/*
 * Copyright 2009 David Jurgens
 *
 * This file is part of the S-Space package and is covered under the terms and
 * conditions therein.
 *
 * The S-Space package is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as published
 * by the Free Software Foundation and distributed hereunder to you.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND NO REPRESENTATIONS OR WARRANTIES,
 * EXPRESS OR IMPLIED ARE MADE.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, WE MAKE
 * NO REPRESENTATIONS OR WARRANTIES OF MERCHANT- ABILITY OR FITNESS FOR ANY
 * PARTICULAR PURPOSE OR THAT THE USE OF THE LICENSED SOFTWARE OR DOCUMENTATION
 * WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER
 * RIGHTS.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

package edu.ucla.sspace.lsa;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOError;
import java.io.IOException;
import java.io.PrintWriter;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

import java.util.concurrent.atomic.AtomicInteger;

import java.util.logging.Logger;

import edu.ucla.sspace.common.SemanticSpace;

import edu.ucla.sspace.matrix.Matrices;
import edu.ucla.sspace.matrix.Matrix;
import edu.ucla.sspace.matrix.SVD;

import edu.ucla.sspace.text.IteratorFactory;

/**
 * An implementation of Latent Semantic Analysis (LSA).  This implementation is
 * based on two papers.
 * <ul>
 *
 *   <li style="font-family:Garamond, Georgia, serif"> Landauer, T. K., Foltz,
 *     P. W., & Laham, D. (1998).  Introduction to Latent Semantic
 *     Analysis. <i>Discourse Processes</i>, <b>25</b>, 259-284.  Available <a
 *     href="http://lsa.colorado.edu/papers/dp1.LSAintro.pdf">here</a> </li>
 *
 * <li style="font-family:Garamond, Georgia, serif"> Landauer, T. K., and
 *    Dumais, S. T. (1997). A solution to Plato's problem: The Latent Semantic
 *    Analysis theory of the acquisition, induction, and representation of
 *    knowledge.  <i>Psychological Review</i>, <b>104</b>, 211-240.  Available
 *    <a href="http://lsa.colorado.edu/papers/plato/plato.annote.html">here</a>
 *    </li>
 *
 * </ul> See the Wikipedia page on <a
 * href="http://en.wikipedia.org/wiki/Latent_semantic_analysis"> Latent Semantic
 * Analysis </a> for an execuative summary.
 *
 * <p>
 *
 * LSA first processes documents into a word-document matrix where each unique
 * word is a assigned a row in the matrix, and each column represents a
 * document.  The values of ths matrix correspond to the number of times the
 * row's word occurs in the column's document.  After the matrix has been built,
 * the <a
 * href="http://en.wikipedia.org/wiki/Singular_value_decomposition">Singular
 * Value Decomposition</a> (SVD) is used to reduce the dimensionality of the
 * original word-document matrix, denoted as <span style="font-family:Garamond,
 * Georgia, serif">A</span>. The SVD is a way of factoring any matrix A into
 * three matrices <span style="font-family:Garamond, Georgia, serif">U &Sigma;
 * V<sup>T</sup></span> such that <span style="font-family:Garamond, Georgia,
 * serif"> &Sigma; </span> is a diagonal matrix containing the singular values
 * of <span style="font-family:Garamond, Georgia, serif">A</span>. The singular
 * values of <span style="font-family:Garamond, Georgia, serif"> &Sigma; </span>
 * are ordered according to which causes the most variance in the values of
 * <span style="font-family:Garamond, Georgia, serif">A</span>. The original
 * matrix may be approximated by recomputing the matrix with only <span
 * style="font-family:Garamond, Georgia, serif">k</span> of these singular
 * values and setting the rest to 0. The approximated matrix <span
 * style="font-family:Garamond, Georgia, serif"> &Acirc; = U<sub>k</sub>
 * &Sigma;<sub>k</sub> V<sub>k</sub><sup>T</sup></span> is the least squares
 * best-?t rank-<span style="font-family:Garamond, Georgia, serif">k</span>
 * approximation of <span style="font-family:Garamond, Georgia, serif">A</span>.
 * LSA reduces the dimensions by keeping only the ?rst <span
 * style="font-family:Garamond, Georgia, serif">k</span> dimensions from the row
 * vectors of <span style="font-family:Garamond, Georgia, serif">U</span>.
 * These vectors form the <i>semantic space</i> of the words.
 *
 * <p>
 *
 * This class offers configurable preprocessing and dimensionality reduction.
 * through three parameters.
 *
 * <dl style="margin-left: 1em">
 *
 * <dt> <i>Property:</i> <code><b>{@value #MATRIX_TRANSFORM_PROPERTY}
 *      </b></code> <br>
 *      <i>Default:</i> {@link LogEntropyTransformer}
 *
 * <dd style="padding-top: .5em">This variable sets the preprocessing algorithm
 *      to use on the term-document matrix prior to computing the SVD.  The
 *      property value should be the fully qualified named of a class that
 *      implements {@link MatrixTransformer}.  The class should be public, not
 *      abstract, and should provide a public no-arg constructor.<p>
 *
 * <dt> <i>Property:</i> <code><b>{@value LSA_DIMENSIONS_PROPERTY}
 *      </b></code> <br>
 *      <i>Default:</i> {@code 300}
 *
 * <dd style="padding-top: .5em">The number of dimensions to use for the
 *       semantic space.  This value is used as input to the SVD.<p>
 *
 * <dt> <i>Property:</i> <code><b>{@value LSA_SVD_ALGORITHM_PROPERTY}
 *      </b></code> <br>
 *      <i>Default:</i> {@link edu.ucla.sspace.matrix.SVD.Algorithm#ANY}
 *
 * <dd style="padding-top: .5em">This property sets the specific SVD algorithm
 *       that LSA will use to reduce the dimensionality of the word-document
 *       matrix.  In general, users should not need to set this property, as the
 *       default behavior will choose the fastest available on the system.<p>
 *
 * </dl> <p>
 *
 * <p>
 *
 * This class is thread-safe for concurrent calls of {@link
 * #processDocument(BufferedReader) processDocument}.  Once {@link
 * #processSpace(Properties) processSpace} has been called, no further calls to
 * {@code processDocument} should be made.  This implementation does not support
 * access to the semantic vectors until after {@code processSpace} has been
 * called.
 *
 * @see MatrixTransformer
 * @see SVD
 *
 * @author David Jurgens
 */
public class LatentSemanticAnalysis implements SemanticSpace {

    /**
     * The prefix for naming publically accessible properties
     */
    private static final String PROPERTY_PREFIX =
        "edu.ucla.sspace.lsa.LatentSemanticAnalysis";

    /**
     * The property to define the {@link MatrixTransformer} class to be used
     * when processing the space after all the documents have been seen.
     */
    public static final String MATRIX_TRANSFORM_PROPERTY =
        PROPERTY_PREFIX + ".transform";

    /**
     * The property to set the number of dimension to which the space should be
     * reduced using the SVD
     */
    public static final String LSA_DIMENSIONS_PROPERTY =
        PROPERTY_PREFIX + ".dimensions";

    /**
     * The property to set the specific SVD algorithm used by an instance during
     * {@code processSpace}.  The value should be the name of a {@link
     * edu.ucla.sspace.matrix.SVD.Algorithm}.  If this property is unset, any
     * available algorithm will be used according to the ordering defined in
     * {@link SVD}.
     */
    public static final String LSA_SVD_ALGORITHM_PROPERTY =
        PROPERTY_PREFIX + ".svd.algorithm";

    /**
     * The name prefix used with {@link #getName()}
     */
    private static final String LSA_SSPACE_NAME =
     "lsa-semantic-space";

    /**
     * The logger used to record all output
     */
    private static final Logger LSA_LOGGER =
        Logger.getLogger(LatentSemanticAnalysis.class.getName());

    /**
     * A mapping from a word to the row index in the that word-document matrix
     * that contains occurrence counts for that word.
     */
    private final ConcurrentMap<String,Integer> termToIndex;

    /**
     * The counter for recording the current, largest word index in the
     * word-document matrix.
     */
    private final AtomicInteger termIndexCounter;

    /**
     * The counter for recording the current, largest document index in the
     * word-document matrix.
     */
    private final AtomicInteger docIndexCounter;

    /**
     * A file in {@link edu.ucla.sspace.common.MatrixIO.Format#MATLAB_SPARSE
     * MATLAB_SPARSE} format.
     */
    private final File rawTermDocMatrix;

    /**
     * The writer to the {@code rawTermDocMatrix}.
     */
    private final PrintWriter rawTermDocMatrixWriter;

    /**
     * The word space of the LSA model, which is the left factor matrix of the
     * SVD of the word-document matrix.  This matrix is only available after the
     * {@link #processSpace(Properties) processSpace} method has been called.
     */
    private Matrix wordSpace;

    /**
     * The document space of the LSA model, which is the right factor matrix of
     * the SVD of the word-document matrix.  This matrix is only available after the
     * {@link #processSpace(Properties) processSpace} method has been called.
     */
    private Matrix documentSpace;

    /**
     * Constructs the {@code LatentSemanticAnalysis} using the system properties
     * for configuration.
     *
     * @throws IOException if this instance encounters any errors when creatng
     *         the backing array files required for processing
     */
    public LatentSemanticAnalysis() throws IOException {
        this(System.getProperties());
    }

    /**
     * Constructs the {@code LatentSemanticAnalysis} using the specified
     * properties for configuration.
     *
     * @throws IOException if this instance encounters any errors when creatng
     *         the backing array files required for processing
     */
    public LatentSemanticAnalysis(Properties properties) throws IOException {

        termToIndex = new ConcurrentHashMap<String,Integer>();
        termIndexCounter = new AtomicInteger(0);
        docIndexCounter = new AtomicInteger(0);

        rawTermDocMatrix =
            File.createTempFile("lsa-term-document-matrix", "dat");
        rawTermDocMatrixWriter = new PrintWriter(rawTermDocMatrix);

        wordSpace = null;
        documentSpace = null;
    }

    /**
     * Parses the document.
     *
     * @param document {@inheritDoc}
     */
    public void processDocument(BufferedReader document) throws IOException {

        Map<String,Integer> termCounts =
            new LinkedHashMap<String,Integer>(1 << 10, 16f);

            Iterator<String> documentTokens =
                IteratorFactory.tokenize(document);

            // for each word in the text document, keep a count of how many
            // times it has occurred
            while (documentTokens.hasNext()) {
                String word = documentTokens.next();

                // Add the term to the total list of terms to ensure it has a
                // proper index.  If the term was already added, this method is
                // a no-op
                addTerm(word);
                Integer termCount = termCounts.get(word);

                // update the term count
                termCounts.put(word, (termCount == null)
                               ? Integer.valueOf(1)
                               : Integer.valueOf(1 + termCount.intValue()));
            }

        document.close();

        // check that we actually loaded in some terms before we increase the
        // documentIndex.  This could possibly save some dimensions in the final
        // array for documents that were essentially blank.  If we didn't see
        // any terms, just return 0
        if (termCounts.isEmpty())
            return;

        int documentIndex = docIndexCounter.incrementAndGet();

        // Once the document has been fully parsed, output all of the sparse
        // data points using the writer.  Synchronize on the writer to prevent
        // any interleaving of output by other threads
        synchronized(rawTermDocMatrixWriter) {
            for (Map.Entry<String,Integer> e : termCounts.entrySet()) {
                String term = e.getKey();
                int count = e.getValue().intValue();
                StringBuffer sb = new StringBuffer(32);
                sb.append(termToIndex.get(term).intValue()).append(" ").
                    append(documentIndex).append(" ").append(count);
                rawTermDocMatrixWriter.println(sb.toString());
            }

            rawTermDocMatrixWriter.flush();
        }

    }

    /**
     * Adds the term to the list of terms and gives it an index, or if the term
     * has already been added, does nothing.
     */
    private void addTerm(String term) {

        Integer index = termToIndex.get(term);

        if (index == null) {

            synchronized(this) {

                // recheck to see if the term was added while blocking
                index = termToIndex.get(term);
                // if some other thread has not already added this term while
                // the current thread was blocking waiting on the lock, then add
                // it.
                if (index == null) {
                    index = Integer.valueOf(termIndexCounter.incrementAndGet());
                    termToIndex.put(term, index);
                }
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public Set<String> getWords() {
        return Collections.unmodifiableSet(termToIndex.keySet());
    }

    /**
     * {@inheritDoc}
     */
    public double[] getVectorFor(String word) {

        // determine the index for the word
        Integer index = termToIndex.get(word);

        // NB: substract 1 from the index value because our output starts at
        // index 1 (not 0), but the wordSpace Matrix starts indexing at 0.
        return (index == null)
            ? null
            : wordSpace.getRow(index.intValue() - 1);
    }

    /**
     * Returns the semantics of the document as represented by a numeric vector.
     * Note that document semantics are represented in an entirely different
     * space, so the corresponding semantic dimensions in the word space will be
     * completely unrelated.  However, document vectors may be compared to find
     * those document with similar content.<p>
     *
     * Similar to {@code getVectorFor}, this method is only to be used after
     * {@code processSpace} has been called.<p>
     *
     * Implementation note: If a specific document ordering is needed, caution
     * should be used when using this class in a multi-threaded environment.
     * Beacuse the document number is based on what order it was
     * <i>processed</i>, no guarantee is made that this will correspond with the
     * original ordering.  However, in a single-threaded environment, the
     * ordering will be maintained.
     *
     * @param documentNumber the number of the document according to when it was
     *        processed
     *
     * @return the semantics of the document in the document space
     */
    public double[] getDocumentVector(int documentNumber) {
        if (documentNumber < 0 || documentNumber >= documentSpace.rows()) {
            throw new IllegalArgumentException(
                "Document number is not within the bounds of the number of "
                + "documents: " + documentNumber);
        }
        return documentSpace.getRow(documentNumber);
    }

    /**
     * {@inheritDoc}
     */
    public String getSpaceName() {
        return LSA_SSPACE_NAME;
    }

    /**
     * {@inheritDoc}
     */
    public int getVectorSize() {
      return wordSpace.columns();
    }

    /**
     * {@inheritDoc}
     *
     * <p>
     *
     * This method is thread-safe and may be called in parallel with separate
     * documents to speed up overall processing time.
     *
     * @param properties {@inheritDoc} See this class's {@link
     *        LatentSemanticAnalysis javadoc} for the full list of supported
     *        properties.
     */
    public void processSpace(Properties properties) {
        try {
            // first ensure that we are no longer writing to the matrix
            synchronized(rawTermDocMatrix) {
                rawTermDocMatrixWriter.close();
            }

            MatrixTransformer transform = new LogEntropyTransformer();

            String transformClass =
                properties.getProperty(MATRIX_TRANSFORM_PROPERTY);
            if (transformClass != null) {
                try {
                    Class clazz = Class.forName(transformClass);
                    transform = (MatrixTransformer)(clazz.newInstance());
                }
                // perform a general catch here due to the number of possible
                // things that could go wrong.  Rethrow all exceptions as an
                // error.
                catch (Exception e) {
                    throw new Error(e);
                }
            }

            LSA_LOGGER.info("performing " + transform + " transform");

            // Convert the raw term counts using the specified transform
            File processedTermDocumentMatrix =
                transform.transform(rawTermDocMatrix);

            int dimensions = 300; // default
            String userSpecfiedDims =
                properties.getProperty(LSA_DIMENSIONS_PROPERTY);
            if (userSpecfiedDims != null) {
                try {
                    dimensions = Integer.parseInt(userSpecfiedDims);
                } catch (NumberFormatException nfe) {
                    throw new IllegalArgumentException(
                        LSA_DIMENSIONS_PROPERTY + " is not an integer: " +
                        userSpecfiedDims);
                }
            }

            LSA_LOGGER.info("reducing to " + dimensions + " dimensions");

            String svdProp = properties.getProperty(LSA_SVD_ALGORITHM_PROPERTY);
            SVD.Algorithm alg = (svdProp == null)
                ? SVD.Algorithm.ANY
                : SVD.Algorithm.valueOf(svdProp);

            // Compute SVD on the pre-processed matrix.
            Matrix[] usv = SVD.svd(processedTermDocumentMatrix,
                                   alg,
                                   dimensions);

            // Load the left factor matrix, which is the word semantic space
            wordSpace = usv[0];
            // We transpose the document space to provide easier access to the
            // document vectors, which in the un-transposed version are the
            // columns.  NOTE: if the Matrix interface ever adds a getColumn()
            // method, it might be better to use that instead.
            documentSpace = Matrices.transpose(usv[2]);

        } catch (IOException ioe) {
            //rethrow as Error
            throw new IOError(ioe);
        }
    }
}