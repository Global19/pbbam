// Author: Derek Barnett

#ifndef FORMAT_UTILS_H
#define FORMAT_UTILS_H

#include "pbbam/Config.h"

#include <string>
#include <vector>

#include <htslib/bgzf.h>

namespace PacBio {
namespace BAM {

enum class HtslibCompression
{
    NONE,
    GZIP,
    BGZIP
};

class FormatUtils
{
public:
    static const std::vector<std::string>& FastaExtensions();
    static const std::vector<std::string>& FastqExtensions();

    static bool IsFastaFilename(const std::string& fn);
    static bool IsFastqFilename(const std::string& fn);

    static HtslibCompression CompressionType(BGZF* fp);
    static HtslibCompression CompressionType(const std::string& fn);

private:
    static bool IsFormat(const std::string& fn, const std::vector<std::string>& extensions);
};

}  // namespace BAM
}  // namespace PacBio

#endif  // FORMAT_UTILS_H
