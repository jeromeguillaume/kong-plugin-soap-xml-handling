////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_XPATH_H
#define SAXON_XPATH_H

#include "SaxonProcessor.h"
//#include "XdmValue.h"
//#include "XdmItem.h"

#include <string>

class SaxonProcessor;
class SaxonApiException;
class XdmValue;
class XdmItem;

enum class UnprefixedElementMatchingPolicy {

  /**
   * The standard W3C policy, whereby element names are implicitly qualified by
   * the default namespace for elements and types, as defined in the XPath
   * static context. In XSLT this can be set using the
   * <code>[xsl:]xpath-default-namespace</code> attribute, or programmatically
   * using {@link XsltCompiler#setDefaultElementNamespace(String)}
   */
  DEFAULT_NAMESPACE = 0,
  /**
   * Under this policy, unprefixed element names match on the local part only;
   * an element with this local name is matched regardless of its namespace
   * (that is, it can have any namespace, or none)
   */
  ANY_NAMESPACE = 1,
  /**
   * Under this policy, unprefixed element names match provided that (a) the
   * local part of the name matches, and (b) the namespace part of the name is
   * either equal to the default namespace for elements and types, or is absent.
   *
   * <p>This policy is provided primarily for use with HTML, where it can be
   * unpredictable whether HTML elements are in the XHTML namespace or in no
   * namespace. It is also useful with other vocabularies where instances are
   * sometimes in a namespace and sometimes not. The policy approximates to the
   * special rules defined in the HTML5 specification, which states that
   * unprefixed names are treated as matching names in the XHTML namespace if
   * the context item for a step is "a node in an HTML DOM", and as matching
   * no-namespace names otherwise; since in the XDM data model it is not
   * possible to make a distinction between different kinds of DOM, this policy
   * allows use of unprefixed names both when matching elements in the XHTML
   * namespace and when matching no-namespace elements</p>
   */
  DEFAULT_NAMESPACE_OR_NONE = 2
};

/*! An <code>XPathProcessor</code> represents a factory to compile, load and
 * execute XPath expressions. <p/>
 */
class XPathProcessor {
public:
  //! Default constructor.
  /*!
    Creates a Saxon-HE XPath product
  */
  XPathProcessor();

  ~XPathProcessor();

  //! Constructor with the SaxonProcessor supplied.
  /*!
    @param proc - Pointer to the SaxonProcessor object
    @param cwd - The current working directory
    @throws SaxonApiException
  */
  XPathProcessor(SaxonProcessor *proc, std::string cwd = "");

  /**
   * XPathProcessor copy constructor.
   * @param other - XPathProcessor
   */
  XPathProcessor(const XPathProcessor &other);

  //! Set the static base URI for XPath expressions compiled using this
  //! XPathCompiler.
  /**
   * The base URI is part of the static context, and is used to resolve any
   * relative URIs appearing within an XPath expression, for example a relative
   * URI passed as an argument to the doc() function. If no static base URI is
   * supplied, then the current working directory is used.
   * @param uriStr
   */
  void setBaseURI(const char *uriStr);

  //! Get the static base URI for XPath expressions compiled using this
  //! XPathCompiler.
  /**
   * @return base URI as string of the xPathProcessor
   */
  const char *getBaseURI();

  //! Compile and evaluate an XPath expression
  /**
   *  @param xpathStr - supplied as a character string
   * @param encoding -  the encoding of the string. If not specified then the
   * platform default encoding is used.
   *  @return XdmValue - representing the results of the expression.
   * @throws SaxonApiException
   */
  XdmValue *evaluate(const char *xpathStr, const char *encoding = nullptr);

  //! Compile and evaluate an XPath expression. The result is expected to be a
  //! single XdmItem or nullptr
  /**
    * @param xpathStr - supplied as a character string
    * @param encoding -  the encoding of the string. If not specified then the
   platform default encoding is used.
    * @return XdmItem - XdmItem object or nullptr if the expression returns an
   empty sequence.
   * If the expression returns a sequence of more than one item, any items after
   the first are ignored.
   * @throws SaxonApiException
  */
  XdmItem *evaluateSingle(const char *xpathStr, const char *encoding = nullptr);

  /** Set the context item
   */
  void setContextItem(XdmItem *item);

  /**
   * set the current working directory
   */
  void setcwd(const char *cwd);

  /** Set the context item from file
   */
  void setContextFile(const char *filename);

  //! Evaluate the XPath expression, returning the effective boolean value of
  //! the result.
  /** @param xpathStr - supplied as a character string
   * @param encoding -  the encoding of the string. If not specified then the
   * platform default encoding is used.
   *  @return bool
   * @throws SaxonApiException
   */
  bool effectiveBooleanValue(const char *xpathStr,
                             const char *encoding = nullptr);

  /**
   * Set a parameter value used in the query
   *
   * @param name  of the parameter, as a string. For namespaced parameter use
   * the JAXP solution i.e. "{uri}name"
   * @param value of the query parameter, or nullptr to clear a previously set
   * value
   * @param withParam Internal use only
   */

  void setParameter(const char *name, XdmValue *value, bool withParam=true);

  /**
   * Remove a parameter (name, value) pair
   *
   * @param name  of the parameter
   * @return bool - outcome of the removal
   */
  bool removeParameter(const char *name);

  //! Set a property specific to the processor in use.
  /**
   * XPathProcessor: set serialization properties (names start with '!' i.e.
   * name "!method" -> "xml") 'o':outfile name, 's': context item supplied as
   * file name
   * @param name of the property
   * @param value of the property
   */
  void setProperty(const char *name, const char *value);

  //! Declare a namespace binding as part of the static context for XPath
  //! expressions compiled using this XPathCompiler
  /**
   *
   * @param prefix The namespace prefix. If the value is a zero-length string,
   * this method sets the default namespace for elements and types.
   * @param uri    The namespace URI. It is possible to specify a zero-length
   * string to "undeclare" a namespace; in this case the prefix will not be
   * available for use, except in the case where the prefix is also a zero
   * length string, in which case the absence of a prefix implies that the name
   *               is in no namespace.
   * Assume the prefix or uri is nullptr.
   */
  void declareNamespace(const char *prefix, const char *uri);

  //! Declare a variable as part of the static context for XPath expressions
  //! compiled using this <code>XPathCompiler</code>.
  /**
   *  It is an error for the XPath expression to refer to a variable unless it
   * has been declared. This method declares the existence of the variable, but
   * it does not bind any value to the variable; that is done later, when the
   * XPath expression is evaluated. The variable is allowed to have any type
   * (that is, the required type is <code>item()*</code>).
   *
   * @param name The name of the variable, expressions as a clark name string
   */
  void declareVariable(const char *name);

  //! Say whether an XPath 2.0, XPath 3.0, XPath 3.1 or XPath 4.0 processor is
  //! required.
  /**
   * Set the language version for the XPath compiler.
   *
   * @param version One of the values 1.0, 2.0, 3.0, 3.05, 3.1, 4.0.
   *              Setting the option to 1.0 requests an XPath 2.0 processor
   * running in 1.0 compatibility mode; this is equivalent to setting the
   * language version to 2.0 and backwards compatibility mode to true.
   *              Requesting "3.05" gives XPath 3.0 plus the extensions defined
   * in the XSLT 3.0 specification (map types and map constructors).
   */
  void setLanguageVersion(const char *version);

  //! Say whether XPath 1.0 backwards compatibility mode is to be used
  /**
   * In backwards compatibility
   * mode, more implicit type conversions are allowed in XPath expressions, for
   * example it is possible to compare a number with a string. The default is
   * false (backwards compatibility mode is off).
   *
   * @param option true if XPath 1.0 backwards compatibility is to be enabled,
   * false if it is to be disabled.
   */
  void setBackwardsCompatible(bool option);

  //! Say whether the compiler should maintain a cache of compiled expressions.
  /**
   * @param caching if set to true, caching of compiled expressions is enabled.
   *                If set to false, any existing cache is cleared, and future
   * compiled expressions will not be cached until caching is re-enabled. The
   * cache is also cleared (but without disabling future caching) if any method
   * is called that changes the static context for compiling expressions, for
   * example declareVariable(QName) or declareNamespace(String, String).
   */

  void setCaching(bool caching);

  //! Set the policy for matching unprefixed element names in XPath expressions
  /**
   * @param policy the policy to be used, possible values: DEFAULT_NAMESPACE =
   * 0, ANY_NAMESPACE = 1 or DEFAULT_NAMESPACE_OR_NONE = 2
   *
   */
  void
  setUnprefixedElementMatchingPolicy(UnprefixedElementMatchingPolicy policy);

  /**
   * Convert an int into an UnprefixedElementMatchingPolicy
   *
   * @param n - the int representing the policy
   */
  UnprefixedElementMatchingPolicy convertEnumPolicy(int n) {
    return static_cast<UnprefixedElementMatchingPolicy>(n);
  }

  //!! Get the policy for matching unprefixed element names in XPath expressions
  /**
   * @return the policy being used
   */
  UnprefixedElementMatchingPolicy getUnprefixedElementMatchingPolicy();

  //! Import a schema namespace
  /**
   * Here we add the element and attribute declarations and type definitions
   * contained in a given namespace to the static context for the XPath
   * expression. <p>This method will not cause the schema to be loaded. This
   * method will not fail if the schema has not been loaded (but in that case
   * the set of declarations and definitions made available to the XPath
   * expression is empty). The schema document for the specified namespace may
   * be loaded before or after this method is called.</p> <p>This method does
   * not bind a prefix to the namespace. That must be done separately, using the
   * declareNamespace(String, String) method.</p>
   *
   * @param uri The schema namespace to be imported. To import declarations in a
   * no-namespace schema, supply a zero-length string.
   */
  void importSchemaNamespace(const char *uri);

  /**
   * Get a parameter value by name
   * @param name - Specified parameter name to get
   * @param withParam Internal use only
   * @return XdmValue
   */
  XdmValue *getParameter(const char *name, bool withParam=true);

  /**
   * Get all parameters as a std::map
   */
  std::map<std::string, XdmValue *> &getParameters();

  /**
   * Get all properties as a std::map
   */
  std::map<std::string, std::string> &getProperties();

  /**
   * Clear parameter values set.
   * Default behaviour (false) is to leave XdmValues in memory.
   * Individual pointers to XdmValue objects have to be deleted in the calling
   * program.
   * @param deleteValues - if true then XdmValues are deleted
   */
  void clearParameters(bool deleteValues = false);

  /**
   * Clear property values set
   */
  void clearProperties();


  /**
   * Checks for pending exceptions without creating a local reference to the
   * exception object
   * @return bool - true when there is a pending exception; otherwise return
   * false
   */

  // const char* checkException();

  /**
   * Checks for pending exceptions without creating a local reference to the
   * exception object
   * @return bool - true when there is a pending exception; otherwise return
   * false
   */
  bool exceptionOccurred();

  //! Clear any exception thrown
  void exceptionClear();

  //! Get the first error message if there are any errors
  /**
   * An XPath expression may have a number of errors reported against it.
   * @return char* - The message of the exception
   */
  const char *getErrorMessage();

  //! Get the first error code if there are any errors
  /**
   * After the execution of the XPath expression there may be  a number of
   * errors reported against it.
   * @return char* - The error code of the exception.
   */
  const char *getErrorCode();

  //! Get the SaxonApiException object created when we have an error
  /**
   * After the execution of the processor if there is an error, then a
   * SaxonApiException is created. NULL returned if there is no error.
   * @return SaxonApiException object of the exception thrown.
   */
  SaxonApiException *getException();

private:
  void createException(const char *message = nullptr);


  SaxonProcessor *proc; /*!< SaxonProcessor pointer to object. This is the
                           object that created the XPathProcessor */
  std::string cwdXP;    /*!< current working directory */
  char *xp_baseURI;
  // jclass  cppClass; /*!< Reference to the XPathProcessor Java class under JNI
  // */
  int64_t cppXP; /*!< The XPathProcessor underlying Java object  */
  std::map<std::string, XdmValue *>
      parameters; /*!< map of parameters used for the transformation as (string,
                     value) pairs */
  std::map<std::string, std::string>
      properties; /*!< map of properties used for the transformation as (string,
                     string) pairs */
  SaxonApiException
      *exception; /*!< exception object created when there is an error */
  UnprefixedElementMatchingPolicy unprefixedElementPolicy;
};

#endif /* SAXON_XPATH_H */
