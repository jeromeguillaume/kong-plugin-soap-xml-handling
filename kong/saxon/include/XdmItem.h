////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_XDMITEM_h
#define SAXON_XDMITEM_h

#include "XdmValue.h"

class SaxonProcessor;

/**
 * The class XdmItem represents an item in a sequence, as defined by the XDM
 * data model. An item is either an atomic value, a node, or a function item.
 * <p>An item is a member of a sequence, but it can also be considered as a
 * sequence (of length one) in its own right. <tt>XdmItem</tt> is a subtype of
 * <tt>XdmValue</tt> because every Item in the XDM data model is also a
 * value.</p> <p>It cannot be assumed that every sequence of length one will be
 * represented by an <tt>XdmItem</tt>. It is quite possible for an
 * <tt>XdmValue</tt> that is not an <tt>XdmItem</tt> to hold a singleton
 * sequence.</p> <p>Saxon provides two concrete subclasses of
 * <code>XdmItem</code>, namely XdmNode and XdmAtomicValue. Users must not
 * attempt to create additional subclasses.</p>
 */
class XdmItem : public XdmValue {

public:
  //! XdmItem default constructor.
  /**
   * Create an empty XdmItem
   */
  XdmItem();

  //! XdmItem constructor created as a wrapper around an existing Saxon Java
  //! object
  /**
   * XdmItem constructor created from a JNI Java object. This is for internal
   * use only
   * @param objRef - The internal Java object for the XdmItem is wrapped here in
   * the C++ XdmItem class
   */
  explicit XdmItem(int64_t);

  //! Copy constructor.
  /**
   * Copy constructor for XdmItem
   */
  XdmItem(const XdmItem &item);

  //! Destructor.
  /**
   * Destructor for XdmItem
   */
  virtual ~XdmItem();

  //! Increment reference count of this XdmItem - Memory management - Internal
  //! use only
  /**
   * this method is used for internal memory management.
   */
  virtual void incrementRefCount();

  //! Decrement reference count of this XdmItem - Memory management - Internal
  //! use only
  /**
   * this method is used for internal memory management.
   */
  virtual void decrementRefCount();

  /**
   * Determine whether the item is an atomic value or some other type of item
   *
   * @return true if the item is an atomic value, false if it is a node or a
   * function (including maps and arrays)
   */
  virtual bool isAtomic();

  /**
   * Determine whether the item is a node or some other type of item
   *
   * @return true if the item is a node, false if it is an atomic value or a
   * function (including maps and arrays)
   */
  virtual bool isNode();

  /**
   * Determine whether the item is a function or some other type of item
   *
   * @return true if the item is a Xdm function item, false if it is an atomic
   * value or a function (including maps and arrays)
   */
  virtual bool isFunction();

  /**
   * Determine whether the item is a map or some other type of item
   *
   * @return true if the item is a Xdm map item, false if it is some other value
   */
  virtual bool isMap();

  /**
   * Determine whether the item is an Array or some other type of item
   *
   * @return true if the item is a Xdm Array item, false if it is some other
   * value
   */
  virtual bool isArray();

  /**
   * Get Java XdmValue object.
   * @return jobject - The Java object of the XdmValue in its JNI representation
   */
  virtual int64_t getUnderlyingValue();

  //! Get the string value of the item.
  /**
   * For a node, this gets the string value of the node.
   * For an atomic value, it has the same effect as casting the
   * value to a string. In all cases the result is the same as applying the
   * XPath string() function. <p>For atomic values, the result is the same as
   * the result of calling <code>toString</code>. This is not the case for
   * nodes, where <code>toString</code> returns an XML serialization of the
   * node. The caller should deallocate memory using `delete`.</p>
   *
   * @return the result of converting the item to a string.
   */
  virtual const char *getStringValue();

  //! The toString() method returns a simple XML serialization of the node with
  //! defaulted serialization parameters. The caller should deallocate memory
  //! using `delete`
  const char *toString();

  /**
   * Get the first item in the sequence
   * @return XdmItem or nullptr if sequence is empty
   */
  virtual XdmItem *getHead();

  /**
   * Get the n'th item in the value, counting from zero.
   *
   * @param n the item that is required, counting the first item in the sequence
   * as item zero
   * @return the n'th item in the sequence making up the value, counting from
   * zero return nullptr  if n is less than zero or greater than or equal to the
   * number of items in the value return nullptr if the value is lazily
   * evaluated and the delayed evaluation fails with a dynamic error.
   */
  XdmItem *itemAt(int n);

  /**
   * Get the number of items in the sequence
   * @return the number of items in the value. For an item (including a map or
   * array) this is always 1 (one).
   */
  int size();

  /**
   * Get the type of the object
   */
  virtual XDM_TYPE getType();

protected:
  int64_t value;            /*!< The Java XdmItem reference in Graalvm  */
  const char *stringValue;  /*!< Cached. String representation of the XdmValue,
                               if available */
  const char *itemToString; /*!< Cached. String representation of the XdmValue,
                               if available */
};

#endif
