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
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;

import java.util.HashMap;
import java.util.Map;

import java.util.logging.Logger;

import static edu.ucla.sspace.common.Statistics.log2;
import static edu.ucla.sspace.common.Statistics.log2_1p;

/**
 * Transforms a term-document matrix using log and entropy techniques.  See the
 * following papers for details and analysis:
 *
 * <ul>
 *
 * <li style="font-family:Garamond, Georgia, serif"> Landauer, T. K., Foltz,
 *      P. W., & Laham, D. (1998).  Introduction to Latent Semantic
 *      Analysis. <i>Discourse Processes</i>, <b>25</b>, 259-284.</li>
 *
 * <li style="font-family:Garamond, Georgia, serif"> S. Dumais, �Enhancing
 *      performance in latent semantic indexing (LSI) retrieval,� Bellcore,
 *      Morristown (now Telcordia Technologies), Tech. Rep. TM-ARH-017527,
 *      1990. </li>
 *
 * <li style="font-family:Garamond, Georgia, serif"> P. Nakov, A. Popova, and
 *      P. Mateev, �Weight functions impact on LSA performance,� in
 *      <i>Proceedings of the EuroConference Recent Advances in Natural Language
 *      Processing, (RANLP�01)</i>, 2001, pp. 187�193. </li>
 *
 * </ul>
 *
 * @author David Jurgens
 */
public class LogEntropyTransformer implements MatrixTransformer {

    /*
     * Implementation Reminder: This class could be improved through converting
     * it to use the common.Matrix implementations.
     */

    private static final Logger LOGGER =
        Logger.getLogger(LogEntropyTransformer.class.getName());

    /**
     *
     */
    public LogEntropyTransformer() { }

    public File transform(File input) throws IOException {
        // create a temp file for the output
        File output = File.createTempFile(input.getName() +
                                          ".log-entropy-transform", "dat");
        transform(input, output);
        return output;
    }

    /**
     * Transforms the matrix contained in the {@code input} argument, writing
     * the results to the {@code output} file.
     */
    public void transform(File input, File output) throws IOException {

        Map<Integer,Integer> docToNumTerms = new HashMap<Integer,Integer>();

        int numDocs = 0;

        Map<Integer,Integer> termToGlobalCount = new HashMap<Integer,Integer>();

        int globalTermCount = 0;

        // calculate how many terms were in each document for the original
        // term-document matrix
        BufferedReader br = new BufferedReader(new FileReader(input));
        for (String line = null; (line = br.readLine()) != null; ) {

            String[] termDocCount = line.split("\\s+");

            Integer term  = Integer.valueOf(termDocCount[0]);
            int doc   = Integer.parseInt(termDocCount[1]);
            Integer count = Integer.valueOf(termDocCount[2]);

            if (doc > numDocs)
                numDocs = doc;

            Integer termGlobalCount = termToGlobalCount.get(term);
            termToGlobalCount.put(term, (termGlobalCount == null)
                                  ? count
                                  : termGlobalCount + count);
        }

        br.close();

        LOGGER.fine("calculating term entropy");

        Map<Integer,Double> termToEntropySum = new HashMap<Integer,Double>();

        // now go through and find the probability that the term appears in the
        // document given how many terms it has to begin with
        br = new BufferedReader(new FileReader(input));
        for (String line = null; (line = br.readLine()) != null; ) {
            String[] termDocCount = line.split("\\s+");

            Integer term  = Integer.valueOf(termDocCount[0]);
            Integer doc   = Integer.valueOf(termDocCount[1]);
            Integer count = Integer.valueOf(termDocCount[2]);

            double probability = count.doubleValue() /
                termToGlobalCount.get(term).doubleValue();

            double d = (probability * log2(probability));

            // NOTE: keep the entropy sum a positive value
            Double entropySum = termToEntropySum.get(term);
            termToEntropySum.put(term, (entropySum == null)
                                 ? d : entropySum + d);
        }
        br.close();


        LOGGER.fine("generating new matrix");

        PrintWriter pw = new PrintWriter(output);

        // Last, rewrite the original matrix using the log-entropy
        // transformation describe on page 17 of Landauer et al. "An
        // Introduction to Latent Semantic Analysis"
        br = new BufferedReader(new FileReader(input));
        for (String line = null; (line = br.readLine()) != null; ) {
            String[] termDocCount = line.split("\\s+");

            Integer term  = Integer.valueOf(termDocCount[0]);
            Integer doc   = Integer.valueOf(termDocCount[1]);
            Integer count = Integer.valueOf(termDocCount[2]);

            double log = log2_1p(count);

            double entropySum = termToEntropySum.get(term).doubleValue();
            double entropy = 1 + (entropySum / log2(numDocs));

            // now print out the noralized values
            pw.println(term + "\t" +
                       doc + "\t" +
                       (log * entropy));
        }
        br.close();
        pw.close();
    }

    public String toString() {
        return "log-entropy";
    }

}