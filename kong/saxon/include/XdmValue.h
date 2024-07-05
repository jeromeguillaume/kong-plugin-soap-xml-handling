////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_XDMVALUE_H
#define SAXON_XDMVALUE_H

#include "SaxonCGlue.h"
#include "SaxonCXPath.h"
#include "SaxonProcessor.h"
#include <deque>
#include <list>
#include <string.h>
#include <typeinfo> //used for testing only
#include <vector>

class SaxonProcessor;
class XdmItem;
class XdmAtomicValue;
class XdmNode;

typedef enum saxonTypeEnum {
  enumNode,
  enumString,
  enumInteger,
  enumDouble,
  enumFloat,
  enumBool,
  enumArrXdmValue
} PRIMITIVE_TYPE;

/*! An <code>XdmValue</code> represents a value in the XDM data model. A value
 * is a sequence of zero or more items, each item being an atomic value, a node,
 * or a function item. This class is a wrapper of the XdmValue object created in
 * Java. <p/>
 */
class XdmValue {

public:
  //! A default Constructor.
  /**
   * Create a empty value
   */
  XdmValue() { initialize(); }

  //! A copy constructor.
  /**
   *
   * @param other - XdmValue
   */
  XdmValue(const XdmValue &other);

  //! Add an XdmItem  to the sequence
  /**
   * This method is designed for the primitive types.
   * @param tStr - specify target type of the value
   * @param val - Value to convert
   */
  XdmValue *addXdmValueWithType(const char *tStr,
                                const char *val); // TODO check and document

  /**
   * Add an XdmItem to the sequence.
   * See functions in SaxonCXPath of the C library
   * @param val - XdmItem object
   */
  void addXdmItem(XdmItem *val);

  /**
   * Add an XdmItem to the sequence, when the sequence was returned from SaxonC: Internal use only.
   * @param val - XdmItem object
   */
  void addXdmItemFromUnderlyingValue(XdmItem *val);

  /**
   * Add an Java XdmValue object to the sequence.
   * See methods the functions in SaxonCXPath of the C library
   * @param val - Java object
   */
  void addUnderlyingValue(int64_t val);

  //! A Constructor for handling XdmArray - Internal user only
  /**
   * Handles a sequence of XdmValues given as a  wrapped an Java XdmValue
   * object.
   * @param val - Java XdmValue object
   * @param arrFlag - Currently not used but allows for overloading of
   * constructor methods
   */
  XdmValue(int64_t val, bool arrFlag);

  //! A Constructor
  /**
   * Wrap a Java XdmValue object.
   * @param val - Java XdmValue object
   */
  XdmValue(int64_t val);

  //! Destructor.
  /**
   * Destructor for this XdmValue
   */
  virtual ~XdmValue();

  //! This is deprecated and a no-op, C++ destructor handles this case. Delete
  //! the XdmValue object and clean up all items in the sequence. Release
  //! the underlying JNI object.
  /*
   *! @deprecated
   */
  void releaseXdmValue();

  //! Get the first item in the sequence
  /**
   *
   * @return XdmItem or nullptr if sequence is empty
   * Pointer to XdmItem objects have to be deleted in the calling program.
   */
  virtual XdmItem *getHead();

  //! Get the n'th item in the value, counting from zero.
  /**
   *
   *
   * @param n the item that is required, counting the first item in the sequence
   * as item zero
   * @return the n'th item in the sequence making up the value, counting from
   * zero return nullptr  if n is less than zero or greater than or equal to the
   * number of items in the value.
   * Pointer to XdmItem objects have to be deleted in the calling program.
   */
  virtual XdmItem *itemAt(int n);

  /**
   * Get the number of items in the sequence
   *
   */
  virtual int size();

  //! Create a string representation of the value.
  /**
   * The is the result of serializing
   * the value using the adaptive serialization method.
   * @return a string representation of the value
   */
  virtual const char *toString();

  //! Get the number of references on this XdmValue
  /**
   * This method is used for internal memory management.
   */
  int getRefCount() {
    if (getenv("SAXONC_DEBUG_FLAG")) {
      std::cerr << "getRefCount-xdmVal=" << refCount << " ob ref=" << (this)
                << std::endl;
    }
    return refCount;
  }

  //! Increment reference count of this XdmValue - Memory management - Internal
  //! use only
  /**
   * this method is used for internal memory management.
   */
  virtual void incrementRefCount();

  //! Decrement reference count of this XdmValue - Memory management - Internal
  //! use only
  /**
   * this method is used for internal memory management.
   */
  virtual void decrementRefCount();

  /**
   * Get Java XdmValue object.
   * @return jobject - The Java object of the XdmValue in its JNI representation
   */
  virtual int64_t getUnderlyingValue();

  /**
   * Get the type of the object
   */
  virtual XDM_TYPE getType();

  /**
    * Internal method used to reset associated reference counts on xdmItems that have been relinquished
    */
  void resetRelinquishedItems();

  /**
    * Internal method used to increment the ref count for an relinquished item only once
    */
  void incrementRefCountForRelinquishedValue(int i);

protected:
  //! initialize this XdmValue with default values
  inline void initialize() {
    jValues = SXN_UNSET;
    refCount = 0;
    valueType = nullptr;
    xdmSize = 0;
    toStringValue = nullptr;
    values_cap = 0;
    values = nullptr;
    relinquished_values = nullptr;
    // relinquished_values[0] = 0;
  }

  char *valueType; /*!< Cached. The type of the XdmValue */

  XdmItem **values; /*!< Cached. XdmItems in the XdmValue */
  char *relinquished_values; /*!< Pointer to the array of items which have been relinquished */
  int values_cap; /*!< The count of items in the value */
  int xdmSize;  /*!< Cached. The count of items in the XdmValue */
  int refCount; /*!< The reference count of this XdmValue. If >1 this object
                   should not be deleted */

private:
  char *toStringValue; /*!< Cached. String representation of the XdmValue, if
                          available */
  int64_t jValues;     /*!< If this XdmValue is a sequence we store values as an
                          ProcessorDataAccumulator object  */

  int addXdmItemToValue(XdmItem *val);
};

#endif /** SAXON_XDMVALUE_H **/
