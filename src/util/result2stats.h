#ifndef RESULT2PROFILE_H
#define RESULT2PROFILE_H

#include "Parameters.h"
#include "DBReader.h"
#include "DBWriter.h"

#include <unordered_map>

class StatsComputer {
public:
    enum {
        STAT_LINECOUNT,
        STAT_MEAN,
        STAT_DOOLITTLE,
        STAT_CHARGES,
        STAT_SEQLEN,
        STAT_FIRSTLINE,
        STAT_UNKNOWN
    };


    StatsComputer(const Parameters &par);

    ~StatsComputer();

    int run();

    static float averageValueOnAminoAcids(const std::unordered_map<char, float> &values, const char *seq);

private:
    int stat;

    std::string queryDb;
    std::string queryDbIndex;

    std::string targetDb;
    std::string targetDbIndex;

    DBReader<unsigned int> *resultReader;
    DBWriter *statWriter;

    template<typename T>
    struct PerSequence {
        typedef T(*type)(const char *);
    };

    template<typename T>
    int sequenceWise(typename PerSequence<T>::type call, bool onlyResultDb = false);

    int countNumberOfLines();

    int meanValue();
};


#endif
