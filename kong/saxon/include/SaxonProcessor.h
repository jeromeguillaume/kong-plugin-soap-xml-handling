////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_PROCESSOR_H
#define SAXON_PROCESSOR_H

#if defined __linux__ || defined __APPLE__

#include <dlfcn.h>
#include <stdlib.h>
#include <string>

#define HANDLE void *
#define LoadLibrary(x) dlopen(x, RTLD_LAZY)
#define GetProcAddress(x, y) dlsym(x, y)
#else
#include <windows.h>
#endif

//#define DEBUG //remove
//#define MEM_DEBUG //remove
#define CVERSION "12.5.0"
#define CVERSION_API_NO 1210

#include <iostream>
#include <map>
#include <sstream>
#include <stdexcept> // std::logic_error
#include <string>
#include <vector>

#include "DocumentBuilder.h"
#include "SaxonApiException.h"
#include "SaxonCGlue.h"
#include "SaxonCXPath.h"
#include "SchemaValidator.h"
#include "XPathProcessor.h"
#include "XQueryProcessor.h"
#include "Xslt30Processor.h"
#include "XsltExecutable.h"
//#include "com_saxonica_functions_extfn_PhpCall.h"
//#include "com_saxonica_functions_extfn_PhpCall_PhpFunctionCall.h"
//#define MEM_DEBUG
#if defined MEM_DEBUG

#include <algorithm>
#include <cstdlib>
#include <new>

static std::vector<void *> myAlloc;

void *newImpl(std::size_t sz, char const *file, int line);

void *operator new(std::size_t sz, char const *file, int line);

void *operator new[](std::size_t sz, char const *file, int line);

void operator delete(void *ptr) noexcept;

void operator delete(void *, std::size_t) noexcept;

#endif

class Xslt30Processor;

class XQueryProcessor;

class XPathProcessor;

class SchemaValidator;

class XdmValue;

class XdmNode;

class XdmItem;

class XdmAtomicValue;

class XdmFunctionItem;

class XdmArray;

class XdmMap;

class XsltExecutable;

class DocumentBuilder;

class SaxonApiException;

typedef enum eXdmType {
  XDM_VALUE = 0,
  XDM_ATOMIC_VALUE = 1,
  XDM_NODE = 2,
  XDM_ARRAY = 3,
  XDM_MAP = 4,
  XDM_FUNCTION_ITEM = 5,
  XDM_EMPTY = 6,
  XDM_ITEM = 7,
} XDM_TYPE;

//==========================================

//! The <code>SaxonProcessor</code> class acts as a factory for generating
//! XQuery, XPath, Schema and XSLT compilers.
/*! The <code>SaxonProcessor</code> class not only generates XQuery, XPath,
 * Schema and XSLT Processors, but is used to create Xdm objects from primitive
 * types.
 */
class SaxonProcessor {

  friend class DocumentBuilder;

  friend class Xslt30Processor;

  friend class XsltExecutable;

  friend class XQueryProcessor;

  friend class SchemaValidator;

  friend class XPathProcessor;

  friend class XdmValue;

  friend class XdmAtomicValue;

  friend class XdmFunctionItem;

  friend class XdmNode;

  friend class XdmMap;

  friend class XdmArray;

public:
  //! A default constructor.
  /*!
   * Create Saxon Processor.
   * @throws SaxonApiException
   */

  SaxonProcessor();

  //! constructor based upon a Saxon configuration file.
  /*!
   * Create Saxon Processor.
   * @throws SaxonApiException
   */

  SaxonProcessor(const char *configFile);

  //! A constructor.
  /*!
   * Create Saxon Processor.
   * @param l - Flag that a license is to be used. Default is false.
   * @throws SaxonApiException
   */
  SaxonProcessor(bool l);

  //! The copy assignment= operator
  /*!
   * Create a copy of the Saxon Processor.
   * @param other - SaxonProcessor object
   */
  SaxonProcessor &operator=(const SaxonProcessor &other);

  //! SaxonProcessor copy constructor.
  /**
   *
   * @param other - SaxonProcessor
   */
  SaxonProcessor(const SaxonProcessor &other);

  //! Destructor method. At the end of the program call the release() method to
  //! clear the JVM.
  ~SaxonProcessor();

  //! Get any error message thrown by the processor
  /*!
   * @return string value of the error message. JNI exceptions thrown by this
   * processor are handled internally and can be retrieved by this method.
   */
  const char *getErrorMessage();

  //! Create a DocumentBuilder.
  /**
   * A DocumentBuilder is used to load source XML documents.
   *
   * @return a newly created DocumentBuilder
   */
  DocumentBuilder *newDocumentBuilder();

  //! Create an Xslt30Processor.
  /*!
   * An Xslt30Processor is used to compile XSLT30 stylesheets.
   * @return a newly created Xslt30Processor
   */
  Xslt30Processor *newXslt30Processor();

  //! Create an XQueryProcessor.
  /*!
   * An XQueryProcessor is used to compile XQuery queries.
   *
   * @return a newly created XQueryProcessor
   */
  XQueryProcessor *newXQueryProcessor();

  //! Create an XPathProcessor. An XPathProcessor is used to compile XPath
  //! expressions.
  /*!
   *
   *
   * @return a newly created XPathProcessor
   */
  XPathProcessor *newXPathProcessor();

  //! Create a SchemaValidator which can be used to validate instance documents
  //! against the schema held by this SchemaManager
  /**
   *
   *
   * @return a new SchemaValidator
   */
  SchemaValidator *newSchemaValidator();

  //! Factory method. Unlike the constructor, this avoids creating a new
  //! StringValue in the case
  /*!
   *
   * of a zero-length string (and potentially other strings, in future)
   *
   * @param str the String value. NULL is taken as equivalent to "".
   * @param encoding -  the encoding of the string. If not specified then the
   * platform default encoding is used.
   * @return the corresponding StringValue
   */
  XdmAtomicValue *makeStringValue(std::string str,
                                  const char *encoding = nullptr);

  //! Factory method. Unlike the constructor, this avoids creating a new
  //! StringValue in the case
  /*!
   *
   * of a zero-length string (and potentially other strings, in future)
   *
   * @param str - the char pointer array. nullptr is taken as equivalent to "".
   * @param encoding -  the encoding of the string. If not specified then the
   * platform default encoding is used.
   * @return the corresponding StringValue
   */
  XdmAtomicValue *makeStringValue(const char *str,
                                  const char *encoding = nullptr);

  /*!
   * Factory method: makes either an Int64Value or a BigIntegerValue depending
   * on the value supplied
   *
   * @param i the supplied primitive integer value
   * @return the value as a XdmAtomicValue which is a BigIntegerValue or
   * Int64Value as appropriate
   */
  XdmAtomicValue *makeIntegerValue(int i);

  //! Factory method. make an XdmAtomicValue from a primitive double value
  /*!
   *
   * @param d the value of the double
   * @return a new XdmAtomicValue
   */
  XdmAtomicValue *makeDoubleValue(double d);

  //! Factory method. make an XdmAtomicValue from a primitive float value
  /*!
   *
   *
   * @param f the value of the float
   * @return a new XdmAtomicValue
   */
  XdmAtomicValue *makeFloatValue(float f);

  //! Factory method: makes either an Int64Value or a BigIntegerValue depending
  //! on the value supplied
  /*!
   *
   *
   * @param l the supplied primitive long value
   * @return the value as a XdmAtomicValue which is a BigIntegerValue or
   * Int64Value as appropriate
   */
  XdmAtomicValue *makeLongValue(long l);

  //! Factory method: makes a XdmAtomicValue representing a boolean Value
  /*!
   *
   *
   * @param b true or false, to determine which boolean value is
   *              required
   * @return the XdmAtomicValue requested
   */
  XdmAtomicValue *makeBooleanValue(bool b);

  //! Create an QName Xdm value from string representation in clark notation
  /**
   *
   * @param str - The value given in a string form in clark notation. {uri}local
   * @return XdmAtomicValue - value
   */
  XdmAtomicValue *makeQNameValue(const char *str);

  //! Create an Xdm Atomic value from string representation
  /*!
   *
   * @param type    - Local name of a type in the XML Schema namespace.
   * @param value - The value given in a string form.
   * In the case of a QName the value supplied must be in clark notation.
   * {uri}local
   * @return XdmValue - value
   */
  XdmAtomicValue *makeAtomicValue(const char *type, const char *value);

  //! Make an XdmArray whose members are from string representation
  /**
   *
   * @param input the input array of booleans
   * @param length - the number of items in the array
   * @return an XdmArray whose members are xs:boolean values corresponding
   * one-to-one with the input
   */
  XdmArray *makeArray(const char **input, int length);

  //! Make an XdmArray whose members are xs:short values
  /**
   *
   * @param input  - the input array of short values
   * @param length - the number of items in the array
   * @return an XdmArray whose members are xs:boolean values corresponding
   * one-to-one with the input
   */
  XdmArray *makeArray(short *input, int length);

  //! Make an XdmArray whose members are xs:int values
  /**
   *
   * @param input  - the input array of int values
   * @param length - the number of items in the array
   * @return an XdmArray whose members are xs:boolean values corresponding
   * one-to-one with the input
   */
  XdmArray *makeArray(int *input, int length);

  //! Make an XdmArray whose members are xs:long values
  /**
   *
   * @param input  - the input array of long values
   * @param length - the number of items in the array
   * @return an XdmArray whose members are xs:boolean values corresponding
   * one-to-one with the input
   */
  XdmArray *makeArray(long long *input, int length);

  /**
   * Make an XdmArray whose members are xs:boolean values
   * @param input  - the input array of boolean values
   * @param length - the number of items in the array
   * @return an XdmArray whose members are xs:boolean values corresponding
   * one-to-one with the input
   */
  XdmArray *makeArray(bool *input, int length);

  //! Make an XdmArray whose members are of type XdmValue
  /**
   *
   * @param values the input array of XdmValue pointers
   * @param length - the number of items in the array
   * @return an XdmArray whose members are XdmValue values corresponding
   * one-to-one with the input
   */
  XdmArray *makeArray(XdmValue **values, int length);

  //! Make an XdmMap whose argument is a map from the standard template library.
  /**
   *
   * @param dataMap  is std::map, which consists of keys as XdmAtomicValue and
   * value is XdmValue.
   * @return an XdmMap whose members are key, value pair given as
   * (XdmAtomicValue, XdmValue)
   */
  XdmMap *makeMap(std::map<XdmAtomicValue *, XdmValue *> dataMap);

  //! Make an XdmMap whose argument is a map from the standard template library.
  /**
   *
   * @param dataMap  is std::map, which consists of keys as std::string and
   * value is XdmValue. Keys are converted to XdmAtomicValue objects
   * @return an XdmMap whose members are key, value pair given as
   * (XdmAtomicValue, XdmValue)
   */
  static XdmMap *makeMap2(std::map<std::string, XdmValue *> dataMap);

  //! Make an XdmMap from an array of keys and values.
  /**
   *
   * @param keys - The keys are given as a pointer array of XdmAtomicValue
   * @param values - The values are given as a pointer array of XdmValue
   * @param len - The length of the arrays given as argument
   * @return an XdmMap whose members are key, value pair given as
   * (XdmAtomicValue, XdmValue)
   */
  XdmMap *makeMap3(XdmAtomicValue **keys, XdmValue **values, int len);

  //! Convert clark name string to EQName notation.
  /**
   * The expanded name, as a string using the notation defined by the EQName
   * production in XPath 3.0. If the name is in a namespace, the resulting
   * string takes the form <code>Q{uri}local</code>. Otherwise, the value is the
   * local part of the name.
   * @param name - The URI in Clark notation: <code>{uri}local</code> if the
   *                name is in a namespace, or simply <code>local</code> if not.
   * @return the expanded name, as a string using the notation defined by the
   * EQName production in XPath 3.0.
   */
  const char *clarkNameToEQName(const char *name);

  //! Convert EQName string to clark name notation.
  /**
   *
   * @param name - The URI in EQName notation: <code>Q{uri}local</code> if the
   *               name is in a namespace. For a name in no namespace, either of
   * the forms <code>Q{}local</code> or simply <code>local</code> are accepted.
   * @return the URI in the clark notation
   */
  const char *EQNameToClarkName(const char *name);

  //! Get the string representation of the XdmValue.
  /**
   * @param item - The XdmItem
   * @return string value as char array
   */
  const char *getStringValue(XdmItem *item);

  //! Parse a lexical representation of the source document and return it as an
  //! XdmNode
  /**
   *
   * @param source the source document as a lexical string
   * @param encoding the encoding used to decode the source string. If not
   * specified then platform default encoding is used
   * @param validator can be used to supply a SchemaValidator to validate the
   * document. Default is null
   * @return an XdmNode
   * @throws SaxonApiException if there is a failure in the parsing of the XML
   * document
   */
  XdmNode *parseXmlFromString(const char *source,
                              const char *encoding = nullptr,
                              SchemaValidator *validator = nullptr);

  //! Parse a source document file and return it as an XdmNode.
  /**
   *
   * @param source the filename of the source document
   * @param validator can be used to supply a SchemaValidator to validate the
   * document. Default is null
   * @return an XdmNode
   * @throws SaxonApiException  if there ia a failure in the parsing of the XML
   * file
   */
  XdmNode *parseXmlFromFile(const char *source,
                            SchemaValidator *validator = nullptr);

  //! Parse a source document available by URI and return it as an XdmNode.
  /**
   *
   * @param source the URI of the source document
   * @param validator can be used to supply a SchemaValidator to validate the
   * document. Default is null
   * @return an XdmNode
   * @throws SaxonApiException if there ia failure in the parsing of the XML
   * file
   */
  XdmNode *parseXmlFromUri(const char *source,
                           SchemaValidator *validator = nullptr);

  //! Parse a lexical representation of the JSON and return it as an
  //! XdmValue
  /**
   *
   * @param source the JSON as a lexical string
   * @param encoding the encoding of the source argument. Argument can be
   * omitted and NULL accepted to use the default platform encoding
   * @return an XdmValue
   * @throws SaxonApiException if there is a failure in the parsing of the JSON
   */
  XdmValue *parseJsonFromString(const char *source,
                                const char *encoding = NULL);

  //! Parse a source JSON file and return it as an XdmValue.
  /**
   *
   * @param source the filename of the JSON. This is a full path filename or a
   * URI
   * @return an XdmValue
   * @throws SaxonApiException  if there ia a failure in the parsing of the XML
   * file
   */
  XdmValue *parseJsonFromFile(const char *source);

  //! Get the kind of node.
  /**
   *
   * @param obj - The Java object representation of the XdmNode
   * @return the kind of node, for example ELEMENT or ATTRIBUTE
   */
  int getNodeKind(int64_t obj);

  //! Test whether this processor is schema-aware
  /**
   *
   * @return true if this this processor is licensed for schema processing,
   * false otherwise
   */
  bool isSchemaAwareProcessor();

  //! Checks for thrown exceptions
  /**
   *
   * @return bool - true when there is a pending exception; otherwise return
   * false
   */
  bool exceptionOccurred();

  //! Clears any exception that is currently being thrown. If no exception is
  //! currently being thrown, this routine has no effect.
  void exceptionClear();

  //! Utility method for working with SaxonC on Python
  XdmValue **createXdmValueArray(int len) { return (new XdmValue *[len]); }

  //! Utility method for Python API - internal use only
  /**
   * This method deletes a XdmValue pointer array
   * @param arr - XdmValue pointer array
   * @param len - length of the array
   */
  void deleteXdmValueArray(XdmValue **arr, int len);

  //! Utility method for working with SaxonC on Python
  XdmAtomicValue **createXdmAtomicValueArray(int len) {
    return (new XdmAtomicValue *[len]);
  }

  //! Utility method for Python API - internal use only
  /**
   * This method deletes a XdmAtomicValue pointer array
   * @param arr - XdmAtomicValue pointer array
   * @param len - length of the array
   */
  void deleteXdmAtomicValueArray(XdmAtomicValue **arr, int len);

  //! Checks for pending exceptions and creates a SaxonApiException object,
  //! which handles one or more local exceptions objects
  static SaxonApiException *checkForExceptionCPP(
      /*JNIEnv *env, jclass callingClass, jobject callingObject*/);

  //! Clean up and destroy Java VM to release memory used. Method to be called
  //! at the end of the program
  static void release();

  //! Attaches a current thread to the a Java VM
  static void attachCurrentThread();

  //! Detach JVM from the current thread
  static void detachCurrentThread();

  //! Set the current working directory
  void setcwd(const char *cwd);

  //! Get the current working directory
  /**
   *
   * @return string value of the cwd
   */
  const char *getcwd();

  //! Get saxon resources directory
  /**
   *
   * @return string value of the resource directory
   */
  const char *getResourcesDirectory();

  //! set saxon resources directory
  void setResourcesDirectory(const char *dir);

  /**
   * set catalog to be used in Saxon
   * @param catalogFile file name to the catalog
   * @throws SaxonApiException if fail to set the catalog file
   * @deprecated
   */
  void setCatalog(const char *catalogFile);

  /**
   * set catalog files to be used in Saxon
   * @param catalogFiles - the catalog file names array to the catalog
   * @param length  - number of catalog files in the array argument
   * @throws SaxonApiException if fail to set the catalog file
   */
  void setCatalogFiles(const char **catalogFiles, int length);

  //! Set a configuration property specific to the processor in use.
  /**
   *
   * Properties specified here are common across all the processors.
   * Example 'l':enable line number has the value 'on' or 'off'
   *
   * @param name of the property
   * @param value of the property
   */
  void setConfigurationProperty(const char *name, const char *value);

  //! Clear configuration properties specific to the processor in use.
  void clearConfigurationProperties();

  //! Get the Saxon version
  /**
   *
   * @return char array
   */
  const char *version();

  //! Add a native method.
  /**
   *
   * @param name of the native method
   * @param signature of the native method
   * @param fnPtr Pointer to the native method
   */
  /*void addNativeMethod(char *name, char *signature, void *fnPtr) {

      JNINativeMethod method;
      method.name = name;
      method.signature = signature;
      method.fnPtr = fnPtr;

      nativeMethodVect.push_back(method);


  }*/

  //! Register several native methods for one class.
  /**
   *
   * @param libName name of the library which contains the function(s). Loads
  the library
   * @param gMethods Register native methods. Default is nullptr, also nullptr
  allowed in which cause assumption is made the user has added native methods
  using the method addNativeMethod .
  * @return bool success of registered native method
  */
  /*bool registerCPPFunction(char *libName, JNINativeMethod *gMethods = nullptr)
  { if (libName != nullptr) { setConfigurationProperty("extc", libName);

      }

      if (gMethods == nullptr && nativeMethodVect.size() == 0) {
          return false;
      } else {
          if (gMethods == nullptr) {
              //copy vector to gMethods
              gMethods = new JNINativeMethod[nativeMethodVect.size()];
          }
          return registerNativeMethods(sxn_environ->env,
  "com/saxonica/functions/extfn/CppCall$PhpFunctionCall", gMethods,
  nativeMethodVect.size());


      }
      return false;
  } */

  //! Register several native methods for one class.
  /**
   * @param env
   * @param className
   * @param gMethods
   * @param numMethods
   * @return bool success of registered native method
   */
  /*static bool registerNativeMethods(JNIEnv *env, const char *className,
                                    JNINativeMethod *gMethods, int numMethods) {
      jclass clazz;
      clazz = env->FindClass(className);
      if (clazz == nullptr) {
          std::cerr << "Native registration unable to find class " << className
  << std::endl; return false;
      }

      if (env->RegisterNatives(clazz, gMethods, numMethods) < 0) {
          // std::cerr<<"RegisterNatives failed for "<< className<<std::endl;
          return false;
      }
      return true;
  } **/

  //! Check for exception thrown in the underlying JNI. Then create the
  //! SaxonApiException class which the user can retrieve
  /**
   *
   * @param cppClass
   * @return The SaxonApiException with information about the exception thrown
   */
  // SaxonApiException *checkAndCreateException(jclass cppClass);

  static int jvmCreatedCPP; /*!< Flag to indicate jvm created - used in memory
                               management */
  static sxnc_environment
      *sxn_environ; /*!< Environment to captures the jni, JVM and handler to the
                       cross compiled SaxonC library. */
  std::string cwd;  /*!< current working directory */

  //! Utility method required for python and PHP extension to delete string
  //! created in the C++ code-base
  /**
  * @param data - the string data to be deleted using the operator delete
  * @param deleteFlag - this is a special case to handle the empty sequence which returns empty string there has not allowed any memory
  */
  static void deleteString(const char *data, char deleteFlag=0) {
    if (data != nullptr && deleteFlag == 0) {
      operator delete((char *)data);
      data = nullptr;
    }
  }


  //! Internal method for diagnostics
  void createHeapDump(bool live);

  /**
   * Get info on objects allocated and still in memory
   */
  static void getInfo();

  /*static JavaVM *jvm;*/

protected:
  // jclass xdmAtomicClass; /*!< The XdmAtomicValue instance */
  // jclass versionClass; /*!< The Version instance */
  // jclass procClass; /*!< The Saxon Processor instance */
  // jclass saxonCAPIClass; /*!< The SaxonCAPI instance */
  std::string cwdV; /*!< current working directory */
  // std::string resources_dir; /*!< current Saxon resources directory */
  std::string versionStr; /*!< The Saxon version string */
  std::map<std::string, XdmValue *>
      parameters; /*!< map of parameters used for the transformation as (string,
                     value) pairs */
  std::map<std::string, std::string>
      configProperties; /*!< map of properties used for the transformation as
                           (string, string) pairs */
  bool licensei; /*!< indicates whether the Processor requires a Saxon that
                    needs a license file (i.e. Saxon-EE) other a Saxon-HE
                    Processor is created  */
  int64_t procRef; //!< ObjectHandle reference to the underlying processor

  // JNINativeMethod *nativeMethods; /*!< native methods variable used in
  // extension methods */ std::vector<JNINativeMethod> nativeMethodVect; /*!<
  // Vector of native methods defined by user */
  SaxonApiException
      *exception; /*!< SaxonApiException object to capture exceptions thrown
                     from the underlying Java code via JNI */

private:
  // void createException(const char *message = nullptr);

  void initialize(bool l);

  void applyConfigurationProperties();

  // SaxonC method for internal use
  static int64_t
  createParameterJArray(std::map<std::string, XdmValue *> parameters,
                        std::map<std::string, std::string> properties,
                        int additions = 0);

  static int64_t
  createParameterJArray2(std::map<std::string, XdmValue *> parameters);

  static int64_t createJArray(XdmValue **values, int length);

  static XdmValue *makeXdmValueFromRef(int64_t valueRef);

  static XdmItem *makeXdmItemFromRef(int64_t valueRef);

  static const char *checkException();
};

//===============================================================================================

#endif /* SAXON_PROCESSOR_H */
