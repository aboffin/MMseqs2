#include <string>
#include <iostream>

#include "TranslateNucl.h"

int main (int argc, const char * argv[])
{
    TranslateNucl * translateNucl = new TranslateNucl(TranslateNucl::CANONICAL);
//    translateNucl->initConversionTable();
    std::string nuclStr = "ATGGATGGTACGGTTATCACCATCAAAATGAGCAGGGGTCAGGATATGCAGCCGACC";
    int length = nuclStr.size();
    char* aa = new char[length/3 + 1];
    translateNucl->translate(aa, (char*)nuclStr.c_str(), length);
    aa[length/3] = '\n';
    std::cout << aa << std::endl;
    delete translateNucl;
    return 0;
}

