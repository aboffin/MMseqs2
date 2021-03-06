#include "NcbiTaxonomy.h"
#include "Debug.h"

int main (int argc, const char **argv) {
    NcbiTaxonomy t("/Users/mirdita/tmp/taxonomy/names.dmp",
                   "/Users/mirdita/tmp/taxonomy/nodes.dmp",
                   "/Users/mirdita/tmp/taxonomy/merged.dmp",
                   "/Users/mirdita/tmp/taxonomy/delnodes.dmp");
    std::vector<int> taxa;
    taxa.push_back(9);
    taxa.push_back(7);
    TaxonNode* node = t.LCA(taxa);
    Debug(Debug::INFO) << node->name << "\n";
}
