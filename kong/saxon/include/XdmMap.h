////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_XDM_MAP_h
#define SAXON_XDM_MAP_h

#include "XdmArray.h"
#include "XdmFunctionItem.h"
#include <string>

#include <map>
#include <set>
#include <stdlib.h>
#include <string.h>

/**
 * A map in the XDM data model. A map is a list of zero or more entries, each of
 * which is a pair comprising a key (which is an atomic value) and a value
 * (which is an arbitrary value). The map itself is an XDM item. <p>An XdmMap is
 * immutable.</p>
 * @since 11
 */
class XdmMap : public XdmFunctionItem {

public:
  //! Default constructor.
  /**
   * Create an empty XdmMap
   */
  XdmMap();

  //! Copy constructor.
  /**
   * Copy constructor for XdmMap
   */
  XdmMap(const XdmMap &d);

  //! Destructor.
  /**
   * Destructor for XdmMap
   */
  virtual ~XdmMap() {}

  //! XdmMap constructor which is a wrapper object from the Java XdmMap object -
  //! internal use
  /**
   * @param obj - The internal Java object for the XdmMap is wrapped here in the
   * C++ XdmMap
   */
  XdmMap(int64_t obj);

  //! Create an XdmMap supplying the entries in the form of a std::map, where
  //! the keys and values in the std::map are XDM values
  /**
   *
   * @param map - a std::map whose entries are the (key, value) pairs
   */
  XdmMap(std::map<XdmAtomicValue *, XdmValue *> map);

  //! Get the number of entries in the map
  /**
   *
   *
   * @return the number of entries in the map. (Note that the
   * <code>size()</code> method returns 1 (one), because an XDM map is an item.)
   */
  int mapSize();

  //! Returns the value to which the specified key is mapped, or NULL if this
  //! map contains no mapping for the key.
  /**
   *
   *
   * @param key the key whose associated value is to be returned.
   * @return the value to which the specified key is mapped, or
   * NULL if this map contains no mapping for the key
   * @remark if null is returned check getException method on the SaxonProcessor
   * object for errors
   */
  XdmValue *get(XdmAtomicValue *key);

  //! Returns the value to which the specified string-valued key is mapped, or
  //! NULL if this map contains no mapping for the key.
  /**
   * This is a convenience method to save the trouble of converting the String
   * to an <code>XdmAtomicValue</code>.
   * @param key the key whose associated value is to be returned. This is
   * treated as an instance of <code>xs:string</code> (which will also match
   *            entries whose key is <code>xs:untypedAtomic</code> or
   * <code>xs:anyURI</code>)
   * @return the value to which the specified key is mapped, or
   * NULL if this map contains no mapping for the key
   */
  XdmValue *get(const char *key);

  //!  Returns the value to which the specified integer-valued key is mapped or
  //!  NULL if this map contains no mapping for the key.
  /**
   * This is a convenience method to save the trouble of converting the integer
   * to an <code>XdmAtomicValue</code>.
   *
   * @param key the key whose associated value is to be returned. This is
   * treated as an instance of <code>xs:integer</code> (which will also match
   *            entries whose key belongs to another numeric type)
   * @return the value to which the specified key is mapped, or NULL if this map
   * contains no mapping for the key
   */
  XdmValue *get(int key);

  //! Returns the value to which the specified double-valued key is mapped,
  //! or NULL if this map contains no mapping for the key. This is a convenience
  //! method to save the trouble of converting the double to an
  //! <code>XdmAtomicValue</code>.
  /**
   *
   * @param key the key whose associated value is to be returned. This is
   * treated as an instance of <code>xs:double</code> (which will also match
   *            entries whose key belongs to another numeric type)
   * @return the value to which the specified key is mapped, or
   * NULL if this map contains no mapping for the key
   */
  XdmValue *get(double key);

  //!  Returns the value to which the specified integer-valued key is mapped
  //! or NULL if this map contains no mapping for the key. This is a convenience
  //! method to save the trouble of converting the integer to an
  //! <code>XdmAtomicValue</code>.
  /**
   *
   * @param key the key whose associated value is to be returned. This is
   * treated as an instance of <code>xs:integer</code> (which will also match
   *            entries whose key belongs to another numeric type)
   * @return the value to which the specified key is mapped, or
   * NULL if this map contains no mapping for the key
   */
  XdmValue *get(long key);

  //! Create a new map containing an additional (key, value) pair.
  /**
   *
   * If there is an existing entry with the same key, it is removed
   * @return a new map containing the additional entry. The original map is
   * unchanged.
   */
  XdmMap *put(XdmAtomicValue *key, XdmValue *value);

  //! Create a new map in which the entry for a given key has been removed.
  /**
   *
   * If there is no entry with the same key, the new map has the same content as
   * the old (it may or may not be the same Java object)
   * @param key - The key to be removed given as an XdmAtomicValue
   * @return a map without the specified entry. The original map is unchanged.
   */
  XdmMap *remove(XdmAtomicValue *key);

  //! Get the keys present in the map in the form of an unordered std::set.
  /**
   *
   * @return an unordered std::set of the keys present in this map, in arbitrary
   * order.
   */
  std::set<XdmAtomicValue *> keySet();

  //! Get the keys present in the map in the form of an unordered pointer array
  //! of XdmAtomicValue.
  /**
   *
   * @return an unordered pointer array of the keys present in this map, in
   * arbitrary order.
   */
  XdmAtomicValue **keys();

  // std::map<XdmAtomicValue*, XdmValue*> asMap();

  //! Returns true if this map contains no key-value mappings.
  /**
   * @return true if this map contains no key-value mappings
   */
  bool isEmpty();

  //! Returns <code>true</code> if this map contains a mapping for the specified
  //! key.
  /**
   * More formally, returns true if and only if
   * this map contains a mapping for a key k such that
   * <tt>(key==null ? k==null : key.equals(k))</tt>.  (There can be
   * at most one such mapping.)
   *
   * @param key key whose presence in this map is to be tested
   * @return <tt>true</tt> if this map contains a mapping for the specified key
   */
  bool containsKey(XdmAtomicValue *key);

  //! Returns a std::list containing the values found in this map, that is, the
  //! value parts of the key-value pairs.
  /**
   *
   *
   * @return a std::list containing the values found in this map. The result
   * may contain duplicates, and the ordering of the collection is
   * unpredictable.
   */
  std::list<XdmValue *> valuesAsList();

  //! Returns a pointer array containing the values found in this map, that is,
  //! the value parts of the key-value pairs.
  /**
   *
   *
   * @return a pointer array containing the values found in this map. The result
   * may contain duplicates, and the ordering of the collection is
   * unpredictable.
   */
  XdmValue **values();

  //! Determine whether the item is a function or some other type of item
  /**
   *
   * @return true if the item is a Xdm function item, false if it is an atomic
   * value or a function (including maps and arrays)
   */
  bool isFunction() { return true; }

  //! Determine whether the item is a map or some other type of item
  /**
   *
   * @return true if the item is a Xdm map item, false if it is some other type
   */
  bool isMap() { return true; }

  //! Get the type of the object
  XDM_TYPE getType() { return XDM_MAP; }

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
  std::map<XdmAtomicValue *, XdmValue *>
      data;  /*!< Cached XdmMap represented internally as an std::map. This can
                also be represented as an JNI object */
  int arity; /*!< The arity of this function  */
  int map_size; /*!< Cached size of the map if  represented as a JNI object*/
};

#endif
