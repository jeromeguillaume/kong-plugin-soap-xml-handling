////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_XDMFUNCTIONITEM_h
#define SAXON_XDMFUNCTIONITEM_h

#include "XdmAtomicValue.h"
#include "XdmItem.h"
#include "XdmNode.h"

#include <string>

#include <stdlib.h>
#include <string.h>

/**
 * The class XdmFunctionItem represents a function item
 */
class XdmFunctionItem : public XdmItem {

public:
  //! Default constructor for XdmFunctionItem.
  /**
   * Create an empty XdmFunctionItem
   */
  XdmFunctionItem();

  //! XdmFunctionItem constructor created from a Java object - internal use
  /**
   * XdmFunctionItem constructor created from a JNI Java object. This is for
   * internal use only
   * @param obj - The internal Java object for the XdmFunctionItem is wrapped
   * here in the C++ XdmArray
   */
  XdmFunctionItem(int64_t obj);

  //! Copy constructor.
  /**
   * Copy constructor for XdmFunctionItem
   */
  XdmFunctionItem(const XdmFunctionItem &d);

  //! Destructor.
  /**
   * Destructor for XdmFunctionItem
   */
  virtual ~XdmFunctionItem() {
    if (fname != nullptr) {
      delete fname;
    }
  }

  //! Get the name of the function as EQName.
  /**
   * The expanded name, as a string using the notation devised by EQName.
   * If the name is in a namespace, the resulting string takes the form
   * <code>Q{uri}local</code>. Otherwise, the value is the local part of the
   * name.
   *
   * @return the function name as a string in the EQName notation, or null for
   * an anonymous inline function item
   */
  const char *getName();

  //! Get the arity of the function
  /**
   *
   *
   * @return the arity of the function, that is, the number of arguments in the
   * function's signature
   */
  virtual int getArity();

  //! Get the string value of the XdmArray item.
  /**
   * Get the string value of the function
   *
   * @return nothing; this method always throws an exception
   */
  const char *getStringValue();

  //! Get a system function
  /**
   * This can be any function defined in XPath 3.1 functions and operators,
   * including functions in the math, map, and array namespaces. It can also be
   * a Saxon extension function, provided a licensed Processor is used.
   *
   * @param processor - The Saxon Processor object required to get the system
   * function
   * @param name - the name of the function
   * @param arity - the number of arguments in the function
   * @return the requested function, or null if there is no such function. Note
   * that some functions (those with particular context dependencies) may be
   * unsuitable for dynamic calling.
   */
  static XdmFunctionItem *getSystemFunction(SaxonProcessor *processor,
                                     const char *name, int arity);

  /**
   * Utility method for working with SaxonC on Python
   */
  XdmValue **createXdmValueArray(int len) { return (new XdmValue *[len]); }

  //! Call the function
  /**
   *
   *
   * @param processor - the SaxonProcessor object required in the call of the
   * function
   * @param arguments  - the values to be supplied as arguments to the function.
   * The "function conversion rules" will be applied to convert the arguments to
   * the required type when necessary.
   * @param argument_length - the length of the array
   * @return the result of calling the function
   */
  XdmValue *call(SaxonProcessor *processor, XdmValue **arguments,
                 int argument_length);

  /**
   * Check if this XdmItem is atomic
   * @return false
   */
  bool isAtomic() { return false; }

  /**
   * Get the type of the object
   */
  XDM_TYPE getType() { return XDM_FUNCTION_ITEM; }

  //! Determine whether the item is a function or some other type of item
  /**
   *
   * @return true if the item is a Xdm function item, false if it is an atomic
   * value or a function (including maps and arrays)
   */
  bool isFunction() { return true; }

protected:
  XdmValue *getXdmValueSubClass(int64_t value); /*!< Creates the right type of result value */

  char *fname; /*!< The name of the function item */

private:
  int arity; /*!< The arity of this function */
};

#endif
