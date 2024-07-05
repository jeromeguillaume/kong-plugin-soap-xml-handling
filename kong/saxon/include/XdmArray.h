////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_XDM_ARRAY_h
#define SAXON_XDM_ARRAY_h

#include "XdmFunctionItem.h"
#include <string>

#include <set>
#include <stdlib.h>
#include <string.h>

/**
 * An array in the XDM data model. An array is a list of zero or more members,
 * each of which is an arbitrary XDM value. The array itself is an XDM item.
 * <p>An XdmArray is immutable.</p>
 *
 */
class XdmArray : public XdmFunctionItem {

public:
  //! XdmArray default constructor.
  /**
   * Create an empty XdmArray
   */
  XdmArray();

  //! Copy constructor.
  /**
   * Copy constructor for XdmArray
   */
  XdmArray(const XdmArray &d);

  //! Destructor.
  /**
   * Destructor for XdmArray
   */
  virtual ~XdmArray() {}

  //! XdmArray constructor which is used a wrapper class for the Java XdmArray
  //! object - internal use
  /**
   * @param obj - The internal Java object for the XdmArray is wrapped here in
   * the C++ XdmArray
   */
  XdmArray(int64_t obj);

  //! XdmArray constructor which is used a wrapper class for the Java XdmArray
  //! object - internal use
  /**
   * @param obj - The internal Java object for the XdmArray is wrapped here in
   * the C++ XdmArray
   * @param len - The length of the array if known
   */
  XdmArray(int64_t obj, int len);

  //! Get the number of members in the array
  /**
   *
   * @return the number of members in the array. (Note that the
   * <code>size()</code> method returns 1 (one), because an XDM array is an
   * item.)
   */
  int arrayLength();

  /**
   * Get the n'th member in the array, counting from zero.
   *
   * @param n the member that is required, counting the first member in the
   * array as member zero
   * @return the n'th member in the sequence making up the array, counting from
   * zero
   * @remark  if n is less than zero or greater than or equal to the number
   *                                    of members in the array we return null.
   * User should clear any exception thrown
   */
  XdmValue *get(int n);

  /**
   * Create a new array in which one member is replaced with a new value.
   *
   * @param n the position of the member that is to be replaced, counting the
   * first member in the array as member zero
   * @param value - is the new member for the the new array
   * @return a new array, the same length as the original, with one member
   * replaced by a new value
   * @remark if n is less than zero or greater than or equal to the number
   *                                   of members in the array then return null
   */
  XdmArray *put(int n, XdmValue *value);

  /**
   * Append a new member to an array
   * @param value - the new member
   * @return a new array, one item longer than the original
   * @remark if the value is lazily evaluated, and evaluation fails then return
   * null
   */
  XdmArray *addMember(XdmValue *value);

  /**
   * Concatenate another array
   *
   * @param value - the other array
   * @return a new array, containing the members of this array followed by the
   * members of the other array
   */
  XdmArray *concat(XdmArray *value);

  /**
   * Get the members of the array in the form of a list.
   * @return a std::list of the members of this array.
   */
  std::list<XdmValue *> asList();

  /**
   * Utility method for working with SaxonC on Python
   * Create an array of xdmValue objects
   * @param len - the length of the array to create
   * @return an empty array of XdmValue of length len
   */
  XdmValue **createXdmValueArray(int len) { return (new XdmValue *[len]); }

  /**
   * Get the members of the array in the form of an array
   * @return an array of the members of this XdmArray.
   */
  XdmValue **values();

  /**
   * Get the arity of the function
   *
   * @return the arity of the function, that is, the number of arguments in the
   * function's signature
   */
  int getArity() { return 1; }

  //! Get the string value of the XdmArray item.
  /**
   * Get the value of the item as a string. For arrays, there is no string
   * value, so an exception is thrown.
   *
   * @return the string value of the item
   */
  const char *getStringValue();

  /**
   * Determine whether the item is a function or some other type of item
   *
   * @return true if the item is a Xdm function item, false if it is an atomic
   * value or a function (including maps and arrays)
   */
  bool isFunction() { return true; }

  /**
   * Get the type of the object
   */
  XDM_TYPE getType() { return XDM_ARRAY; }

  //! Determine whether the item is an array or some other type of item
  /**
   *
   * @return true if the item is a Xdm array item, false if it is some other
   * type
   */
  bool isArray() { return true; }

  //! The toString() method returns a simple XML serialization of the node with
  //! defaulted serialization parameters.
  /**
   *
   * <p>In the case of an element node, the result will be a well-formed
   * XML document serialized as defined in the W3C XSLT/XQuery serialization
   * specification, using options method="xml", indent="yes",
   * omit-xml-declaration="yes".</p> <p>In the case of a document node, the
   * result will be a well-formed XML document provided that the document node
   * contains exactly one element child, and no text node children. In other
   * cases it will be a well-formed external general parsed entity.</p> <p>In
   * the case of an attribute node, the output is a string in the form
   * <code>name="value"</code>. The name will use the original namespace
   * prefix.</p> <p>In the case of a namespace node, the output is a string in
   * the form of a namespace declaration, that is <code>xmlns="uri"</code> or
   * <code>xmlns:pre="uri"</code>.</p> <p>Other nodes, such as text nodes,
   * comments, and processing instructions, are represented as they would appear
   * in lexical XML. Note: this means that in the case of text nodes, special
   * characters such as <code>&amp;</code> and <code>&lt;</code> are output in
   * escaped form. To get the unescaped string value of a text node, use
   * <code>getStringValue()</code> instead.</p>
   *
   * @return a simple XML serialization of the node. Under error conditions the
   * method may return an error message which will always begin with the label
   * "Error: ".
   */
  const char *toString();

private:
  int arrayLen;
};

#endif
