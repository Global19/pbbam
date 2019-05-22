// File Description
/// \file TagCollection.h
/// \brief Defines the TagCollection class.
//
// Author: Derek Barnett

#ifndef TAGCOLLECTION_H
#define TAGCOLLECTION_H

#include "pbbam/Config.h"

#include <map>
#include <string>

#include "pbbam/Tag.h"

namespace PacBio {
namespace BAM {

/// \brief The TagCollection class represents a collection (or "dictionary") of
///        tags.
///
/// Tags are mapped to their tag name, a 2-character string.
///
class PBBAM_EXPORT TagCollection : public std::map<std::string, Tag>
{
public:
    /// \returns true if the collection contains a tag with \p name
    bool Contains(const std::string& name) const;
};

}  // namespace BAM
}  // namespace PacBio

#endif  // TAGCOLLECTION_H
