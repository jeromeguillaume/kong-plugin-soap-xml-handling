////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_XSLT_EXEC_H
#define SAXON_XSLT_EXEC_H

#include "SaxonProcessor.h"
//#include "XdmValue.h"
#include <string>

class SaxonProcessor;
class SaxonApiException;
class Xslt30Processor;
class XdmValue;
class XdmItem;
class XdmNode;
class XdmFunctionItem;

/*! An <code>XsltExecutable</code> represents the compiled form of a stylesheet.
 * <p>An XsltExecutable is created by using one of the <code>compile</code>
 * methods on the Xslt30Processor class.</p>
 */
class XsltExecutable {

  friend class Xslt30Processor;

public:
  ~XsltExecutable();

  //! set the current working directory (cwd). This method also applies to the
  // static base URI for XSLT stylesheets when supplied as lexical string.
  /**
   * The cwd is used to set the base URI is part of the static context, and is
   * used to resolve any relative URIs appearing within XSLT.
   * @param cwd - Current working directory
   */
  void setcwd(const char *cwd);

  //! Set the base output URI.
  /**
   * <p> The base output URI is used for resolving relative URIs in the
   * <code>href</code> attribute of the <code>xsl:result-document</code>
   * instruction; it is accessible to XSLT stylesheet code using the XPath
   * current-output-uri() function</p>
   *
   * @param baseURI - the base output URI
   */
  void setBaseOutputURI(const char *baseURI);

  //! Supply the context item to be used when evaluating global variables and
  //! parameters.
  /**
   * Set the source document from an XdmNode for the transformation.
   * @param value - the item to be used as the context item within the
   * initializers of global variables and parameters. Given as a pointer to the
   * XdmItem object.
   */

  void setGlobalContextItem(XdmItem *value);

  /**
   * Supply the context item to be used when evaluating global variables and
   * parameters. Set the source from file for the transformation.
   * @param filename - the item to be used as the context item within the
   * initializers of global variables and parameters.
   */
  void setGlobalContextFromFile(const char *filename);

  //! Create a clone object of this XsltExecutable object
  /**
   *
   * @return XsltExecutable - new copy of this object
   */
  XsltExecutable *clone();

  //! Set the initial mode for the transformation
  /**
   *
   * @param modeName the EQName of the initial mode. Two special values are
   * recognized, in the reserved XSLT namespace: xsl:unnamed to indicate the
   * mode with no name, and xsl:default to indicate the mode defined in the
   * stylesheet header as the default mode. The value null also indicates the
   * default mode (which defaults to the unnamed mode, but can be set
   * differently in an XSLT 3.0 stylesheet).
   */
  void setInitialMode(const char *modeName);

  //! The initial value to which templates are to be applied (equivalent to the
  //! <code>select</code> attribute of <code>xsl:apply-templates</code>)
  /**
   *  @param selection - The value to which the templates are to be applied
   */
  void setInitialMatchSelection(XdmValue *selection);

  //! The initial filename to which templates are to be applied (equivalent to
  //! the <code>select</code> attribute of <code>xsl:apply-templates</code>).
  /**
   * The file is parsed internally
   *  @param filename - The file name to which the templates are to be applied
   */
  void setInitialMatchSelectionAsFile(const char *filename);

  /**
   * Set the output file of where the transformation result is sent
   */
  void setOutputFile(const char *outfile);

  /**
   *Set true if the return type of callTemplate, applyTemplates and transform
   *methods is to return XdmValue, otherwise return XdmNode object with root
   *Document node
   * @param option true if return raw result, i.e. XdmValue, otherwise return
   *XdmNode
   *
   */
  void setResultAsRawValue(bool option);

  /**
   * Set the value of a stylesheet parameter
   *
   * @param name  the name of the stylesheet parameter, as a string. For
   * namespaced parameter use the JAXP solution i.e. "{uri}name"
   * @param value the value of the stylesheet parameter, or nullptr to clear a
   * previously set value
   */
  void setParameter(const char *name, XdmValue *value);

  /**
   *   Return the result-documents resulting from the execution of the
   * stylesheet. Null is returned if the user has not enabled this feature via
   * the method setCaptureResultDocuments()
   *   @return std::map - the map is indexed by the absolute URI of the result
   * document, and the corresponding value is an XdmNode containing the result
   * document (as an in-memory tree, without serialization)
   *    @throws SaxonApiException if we fail to get result-documents
   */
  std::map<std::string, XdmValue *> &getResultDocuments();

  /**
   * Get a parameter value by name
   * @param name - Specified parameter name to get
   * @param withParam Internal use only
   * @return XdmValue
   */
  XdmValue *getParameter(const char *name, bool withParam=true);

  /**
   * Remove a parameter (name, value) pair from a stylesheet
   *
   * @param name  the name of the stylesheet parameter
   * @return bool - outcome of the removal
   */
  bool removeParameter(const char *name);

  /**
   * Remove a property (name, value) pair from the executable
   *
   * @param name  the name of the property to be removed
   * @return bool - outcome of the removal
   */
  bool removeProperty(const char *name);

  /**
   * Set a property specific to the processor in use.
   * XsltProcessor: set serialization properties (names start with '!' i.e. name
   * "!method" -> "xml") 'o':outfile name, 'it': initial template, 'im': initial
   * mode, 's': source as file name 'm': switch on message listener for
   * xsl:message instructions
   * @param name of the property
   * @param value of the property
   */
  void setProperty(const char *name, const char *value);

  /**
   * Set parameters to be passed to the initial template. These are used
   * whether the transformation is invoked by applying templates to an initial
   * source item, or by invoking a named template. The parameters in question
   * are the xsl:param elements appearing as children of the xsl:template
   * element. <p>The parameters are supplied in the form of a map; the key is a
   * QName given as a string which must match the name of the parameter; the
   * associated value is an XdmValue containing the value to be used for the
   * parameter. If the initial template defines any required parameters, the map
   * must include a corresponding value. If the initial template defines any
   * parameters that are not present in the map, the default value is used. If
   * the map contains any parameters that are not defined in the initial
   * template, these values are silently ignored.</p> <p>The supplied values are
   * converted to the required type using the function conversion rules. If
   * conversion is not possible, a run-time error occurs (not now, but later,
   * when the transformation is actually run).</p> <p>The
   * <code>XsltTransformer</code> retains a reference to the supplied map, so
   * parameters can be added or changed until the point where the transformation
   * is run.</p> <p>The XSLT 3.0 specification makes provision for supplying
   * parameters to the initial template, as well as global stylesheet
   * parameters. Although there is no similar provision in the XSLT 1.0 or 2.0
   * specifications, this method works for all stylesheets, regardless whether
   * XSLT 3.0 is enabled or not.</p>
   *
   * @param parameters the parameters to be used for the initial template
   * @param tunnel     true if these values are to be used for setting tunnel
   * parameters; false if they are to be used for non-tunnel parameters
   */

  void
  setInitialTemplateParameters(std::map<std::string, XdmValue *> parameters,
                               bool tunnel);

  /**
   * Get a property value by name
   * @param name - Specified paramater name to get
   * @return string - Get string of the property as char pointer array
   */
  const char *getProperty(const char *name);

  //! Get all parameters as a std::map
  /**
   *
   * Please note that the key name has been prefixed with 'param:', for example
   * 'param:name'
   * @return std:map with key as string name mapped to XdmValue.
   *
   */
  std::map<std::string, XdmValue *> &getParameters();

  //! Get all properties as a std::map
  /**
   *
   * @return std:map with key as string name mapped to string values.
   */
  std::map<std::string, std::string> &getProperties();

  //! Clear parameter values set.
  /**
   * Default behaviour (false) is to leave XdmValues in memory.
   * Individual pointers to XdmValue objects have to be deleted in the calling
   * program.
   * @param deleteValues - if true then XdmValues are deleted
   */
  void clearParameters(bool deleteValues = false);


  //! Clear property values set
  void clearProperties();

  /**
   * Utility method for working with SaxonC on Python
   */
  XdmValue **createXdmValueArray(int len) { return (new XdmValue *[len]); }

  /**
   * Utility method for working with SaxonC on Python
   */
  char **createCharArray(int len) { return (new char *[len]); }

  //! Utility method for Python API - internal use only
  /**
   * This method deletes a XdmValue pointer array
   * @param arr - XdmValue pointer array
   * @param len - length of the array
   */
  void deleteXdmValueArray(XdmValue **arr, int len);

  //! This method gives users the option to switch on or off the
  //! <code>xsl:message</code> feature.
  /**
   * It is also possible
   * to send the <code>xsl:message</code> outputs to file given by file name.
   * @param show - boolean to indicate if xsl:message should be outputted.
   * Default is on.
   * @param  filename - If the filename argument is present then the xsl:message
   * output is appended to the given filename with location cwd+filename
   */
  void setSaveXslMessage(bool show, const char *filename = nullptr);

  //! Enable the capture of the result-document output into an std:map. This
  //! overrides the default mechanism.
  /**
   * If this option is enabled, then any document created using
   * xsl:result-document is saved (as an XdmNode) in an std::map object where it
   * is accessible using the URI as a key. After the execution of the
   * transformation a call on the <code>getResultDocuments()</code> method is
   * required to get access to the result-documents in the map.
   * @param flag - true causes secondary result documents from the
   * transformation to be saved in a map; false disables this option.
   * @param rawResults - true enables the handling of raw destination for
   * resultsDocuments. If not supplied this can also be set on the
   * setResultAsRawValue method. The setResultAsRawValue method has higher
   * priority to this flag
   */
  void setCaptureResultDocuments(bool flag, bool rawResults = false);

  //! Produce a representation of the compiled stylesheet
  /**
   * The representation of the compiled stylesheet is in an XML form, suitable
   * for distribution and reloading. If the configuration under which the export
   * takes place is suitably licensed, then license information will be included
   * in the export file allowing execution of the stylesheet without any
   * additional license. <p><i>The detailed form of the output representation is
   * not documented.</i></p>
   *
   * @param filename - the destination for the XML document containing the
   * diagnostic representation of the compiled stylesheet. The stream will be
   * closed when writing has finished.
   * @throws SaxonApiException
   */
  void exportStylesheet(const char *filename);

  //! Perform a one shot transformation.
  /**
   * The result is stored in the supplied outputfile.
   *
   * @param sourcefile - The file name of the source document
   * @param outputfile - The file name where results will be stored
   * @throws SaxonApiException
   */
  void transformFileToFile(const char *sourcefile, const char *outputfile);

  //! Perform a one shot transformation.
  /**
   * The result is returned as a string
   *
   * @param sourcefile - The file name of the source document
   * @return char array - result of the transformation
   * @throws SaxonApiException
   */
  const char *transformFileToString(const char *sourcefile);

  /**
   * Perform a one shot transformation. The result is returned as an XdmValue
   *
   * @param sourcefile - The file name of the source document
   * @return XdmValue - result of the transformation
   * @throws SaxonApiException
   */
  XdmValue *transformFileToValue(const char *sourcefile);

  //! Invoke the stylesheet by applying templates to a supplied input sequence,
  //! Saving the results to file.
  /**
   * The initial match selection must be set using one of the two methods
   * setInitialMatchSelection or setInitialMatchSelectionFile. The result is
   * stored in the supplied output file.
   *
   * @param outfile - The file name where results will be stored
   * @throws SaxonApiException
   */
  void applyTemplatesReturningFile(const char *outfile);

  //! Invoke the compiled stylesheet by applying templates to a supplied input
  //! sequence, Saving the results as serialized string.
  /**
   * The initial match selection must be set using one of the two methods
   * setInitialMatchSelection or setInitialMatchSelectionFile.
   * @throws SaxonApiException
   *
   */
  const char *applyTemplatesReturningString();

  //! Invoke the compiled stylesheet by applying templates to a supplied input
  //! sequence, Saving the results as an XdmValue.
  /**
   * The initial match selection must be set using one of the two methods
   * setInitialMatchSelection or setInitialMatchSelectionFile.
   * @throws SaxonApiException
   *
   */
  XdmValue *applyTemplatesReturningValue();

  //! Invoke a transformation by calling a named template and save result to
  //! file.
  /** The results of calling the template are wrapped in a document node, which
   * is then sent to the specified file destination. If
   * setInitialTemplateParameters(std::Map, boolean) has been called, then the
   * parameters supplied are made available to the called template (no error
   * occurs if parameters are supplied that are not used).
   * @param templateName - The name of the initial template. This must match the
   * name of a public named template in the stylesheet. If the value is nullptr,
   * the clark name for xsl:initial-template is used.
   * @param outfile - The file name where results will be stored.
   * @throws SaxonApiException
   */
  void callTemplateReturningFile(const char *templateName, const char *outfile);

  //! Invoke a transformation by calling a named template and return result as a
  //! string.
  /** The results of calling the template are wrapped in a document node, which
   * is then serialized as a string. If setInitialTemplateParameters(std::Map,
   * boolean) has been called, then the parameters supplied are made available
   * to the called template (no error occurs if parameters are supplied that are
   * not used).
   * @param templateName - the name of the initial template. This must match the
   * name of a public named template in the stylesheet. If the value is nullptr,
   * the clark name for xsl:initial-template is used.
   * @throws SaxonApiException
   */
  const char *callTemplateReturningString(const char *templateName = nullptr);

  //! Invoke a transformation by calling a named template and return result as
  //! an XdmValue.
  /** The results of calling the template are wrapped in a document node, which
   * is then returned as an XdmValue. If setInitialTemplateParameters(std::Map,
   * boolean) has been called, then the parameters supplied are made available
   * to the called template (no error occurs if parameters are supplied that are
   * not used).
   * @param templateName - the name of the initial template. This must match the
   * name of a public named template in the stylesheet. If the value is nullptr,
   * the clark name for xsl:initial-template is used.
   * @throws SaxonApiException
   */
  XdmValue *callTemplateReturningValue(const char *templateName = nullptr);

  //! Call a public user-defined function in the already compiled stylesheet
  /** Here we wrap the result in an XML document, and sending this document to a
   * specified file
   * @param functionName - The name of the function to be called
   * @param arguments - Pointer array of XdmValue object - he values of the
   * arguments to be supplied to the function. These will be converted if
   * necessary to the type as defined in the function signature, using the
   * function conversion rules.
   * @param argument_length - the Coutn of arguments objects in the array
   * @param outfile - The file name where results will be stored
   * @throws SaxonApiException
   */
  void callFunctionReturningFile(const char *functionName, XdmValue **arguments,
                                 int argument_length, const char *outfile);

  //! Call a public user-defined function in the compiled stylesheet
  /** Here we wrap the result in an XML document, and serialized this document
   * to string value
   * @param functionName - The name of the function to be called
   * @param arguments - Pointer array of XdmValue object - he values of the
   * arguments to be supplied to the function. These will be converted if
   * necessary to the type as defined in the function signature, using the
   * function conversion rules.
   * @param argument_length - the Count of arguments objects in the array
   * @throws SaxonApiException
   */
  const char *callFunctionReturningString(const char *functionName,
                                          XdmValue **arguments,
                                          int argument_length);

  //! Call a public user-defined function in the already compiled stylesheet
  /** Here we wrap the result in an XML document, and return the document as an
   * XdmValue
   * @param functionName - The name of the function to be called
   * @param arguments - Pointer array of XdmValue object - he values of the
   * arguments to be supplied to the function. These will be converted if
   * necessary to the type as defined in the function signature, using the
   * function conversion rules.
   * @param argument_length - the Count of arguments objects in the array
   * @throws SaxonApiException
   */
  XdmValue *callFunctionReturningValue(const char *functionName,
                                       XdmValue **arguments,
                                       int argument_length);

  //! Execute transformation to string. Properties supplied in advance.
  /**
   * Perform the transformation based upon what has been cached.
   * @param source - source document supplied as an XdmNode object. nullptr
   * accepted if source document has been set already.
   * @return char*. Pointer to Array of chars. Result returned as a string.
   * @throws SaxonApiException
   *
   */
  const char *transformToString(XdmNode *source = nullptr);

  //! Execute transformation to Xdm Value. Properties supplied in advance.
  /**
   * Perform the transformation based upon cached stylesheet and any source
   * document.
   * @param source - source document supplied as an XdmNode object. nullptr
   * accepted if source document has been set already.
   * @return as an XdmValue.
   * @throws SaxonApiException
   *
   */
  XdmValue *transformToValue(XdmNode *source = nullptr);

  //! Execute transformation to file. Properties supplied in advance.
  /**
   * Perform the transformation based upon a compiled stylesheet and source
   * document. Assume the output file has been set in advance
   * @param source - source document supplied as an XdmNode object. nullptr
   * accepted if source document has been set already.
   * @throws SaxonApiException
   */
  void transformToFile(XdmNode *source = nullptr);

  /**
   * Get the messages written using the xsl:message instruction.
   * Returns null if the user has not enabled capturing of xsl:messages via
   * setSaveXslMessage()
   * @return XdmValue - the sequence of xsl:messages as an XdmValue
   */
  XdmValue *getXslMessages();

  /**
   * Clear xsl:message data that are held in the Processor.
   * If the save to file has been enabled then clearXslMessages
   * does not take affect
   */
  void clearXslMessages();

  /**
   * Checks for pending exceptions without creating a local reference to the
   * exception object
   * @return bool - true when there is a pending exception; otherwise return
   * false
   */
  bool exceptionOccurred();

  //! Check for exception thrown and return the SaxonApiException object.
  /**
   * @return SaxonApiException. Returns the exception message if thrown
   * otherwise return nullptr
   */
  SaxonApiException *getException();

  //! Get the first error message if there are any errors
  /**
   * A transformation may have a number of errors reported against it.
   * @return char* - The message of the exception
   */
  const char *getErrorMessage();

  //! Clear any exception thrown
  void exceptionClear();

private:
  //! Default constructor.
  /*!
    Creates a XsltExecutable
  */
  XsltExecutable();

  //! Constructor with the SaxonProcessor supplied.
  /*!
    @param proc - Supplied pointer to the SaxonProcessor object
    cwd - The current working directory
  */
  XsltExecutable(SaxonProcessor *proc, int64_t exObject, std::string cwd,
                 std::string resources);

  /**
   * Xslt30Processor copy constructor.
   * @param other - Xslt30Processor
   */
  XsltExecutable(const XsltExecutable &other);


  void setParameter(const char *name, XdmValue *value, bool withParam);


  SaxonProcessor *proc; /*! Pointer to SaxonProcessor object*/
                        // jclass  cppClass;
  // jclass messageListenerClass, resultDocumentClass;
  int64_t procRef, executableRef, selectionRef, saxonMessageListenerRef,
      saxonResultDocRef;
  bool selectionStringFlag;  /*!< Flag to indicate that the selection was
                                retrieved as a string file value instead of
                                XdmValue */
  std::string cwdXE;         /*!< current working directory */
  std::string resources_dir; /*!< current Saxon resources directory */
  bool tunnel, jitCompilation, rawResultsFlag, exceptionFound;
  std::map<std::string, XdmValue *>
      parameters; /*!< map of parameters used for the transformation as (string,
                     value) pairs */
  std::map<std::string, std::string>
      properties; /*!< map of properties used for the transformation as (string,
                     string) pairs */
  std::map<std::string, XdmValue *> resultDocumentMap;
};

#endif /* SAXON_XSLT_EXEC_H */
