////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_XQUERY_H
#define SAXON_XQUERY_H

#include "SaxonProcessor.h"
#include <string>

class SaxonProcessor;
class SaxonApiException;
class XdmValue;
class XdmItem;

/*! An <code>XQueryProcessor</code> represents a factory to compile, load and
 * execute queries. <p/>
 */
class XQueryProcessor {
public:
  //! Default constructor.
  XQueryProcessor();

  //! Constructor with the SaxonProcessor supplied.
  /*!
   * @param p - Supplied pointer to the SaxonProcessor object
   * @param cwd - set the current working directory. Default is the empty string
   */
  XQueryProcessor(SaxonProcessor *p, std::string cwd = "");

  /**
   * XQueryProcessor copy constructor.
   * @param other - XQueryProcessor
   */
  XQueryProcessor(const XQueryProcessor &other);

  /**
   * Clone the XQueryProcessor with the same internal state, which can be used
   * in separate threads.
   */
  XQueryProcessor *clone();

  ~XQueryProcessor();

  //! Set the initial context item for the query
  /**
    @param value - the initial context item, or nullptr if there is to be no
    initial context item
  */
  void setContextItem(XdmItem *value);

  /**
   * Set the output file where the result is sent
   */
  void setOutputFile(const char *outfile);

  /**
   * Set the source from file for the query.
   */
  void setContextItemFromFile(const char *filename);

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

  //! Set XQuery language version
  /**
   * Say which version of XQuery should be used
   *
   * @param version "3.1" or "4.0" in the current Saxon release.
   */
  void setLanguageVersion(const char *version);

  //! Say whether the query should be compiled and evaluated to use streaming.
  /**
   * This affects subsequent calls on the compile() methods. This option
   * requires Saxon-EE.
   * @param option if true, the compiler will attempt to compile a query to be
   * capable of executing in streaming mode. If the query cannot be streamed, a
   * compile-time exception is reported. In streaming mode, the source document
   * is supplied as a stream, and no tree is built in memory. The default is
   * false. When setStreaming(true) is specified, this has the additional
   * side-effect of setting the required context item type to "document-node()"
   */
  void setStreaming(bool option);

  //! Ask whether the streaming option has been set
  /**
   * Ask whether the streaming option has been set, that is, whether
   * subsequent calls on compile() will compile queries to be capable
   * of executing in streaming mode.
   *
   * @return true if the streaming option has been set.
   */
  bool isStreaming();

  //! Remove a parameter (name, value) pair
  /**
   *
   * @param name  of the parameter
   * @return bool - outcome of the removal
   */
  bool removeParameter(const char *name);

  //! Set a property specific to the processor in use.
  /**
   *
   * XQueryProcessor: set serialization properties (names start with '!' i.e.
   * name "!method" -> "xml") 'o':outfile name, 's': source as file name 'q':
   * query file name, 'q': current by name, 'qs': string form of the query,
   * 'base': set the base URI of the query, 'dtd': set DTD validation 'on' or
   * 'off'
   * @param name of the property
   * @param value of the property
   */
  void setProperty(const char *name, const char *value);

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


  //! Say whether the query is allowed to be updating.
  /**
   * XQuery update syntax will be rejected
   * during query compilation unless this flag is set. XQuery Update is
   * supported only under Saxon-EE.
   * @param updating - true if the query is allowed to use the XQuery Update
   * facility (requires Saxon-EE). If set to false, the query must not be an
   * updating query. If set to true, it may be either an updating or a
   * non-updating query.
   */
  void setUpdating(bool updating);

  //! Perform the Query to file.
  /**
   * The result is is saved to file
   *
   * @param infilename - The file name of the source document
   * @param ofilename - The file name of where result will be stored
   * @param query - The query as string representation.
   * @param encoding -  the encoding of the query string. If not specified then
   * the platform default encoding is used.
   * @throws SaxonApiException
   */
  void executeQueryToFile(const char *infilename, const char *ofilename,
                          const char *query, const char *encoding = nullptr);

  //! Perform the Query to a XdmValue representation.
  /**
   * @param infilename - The file name of the source document
   * @param query - The query as string representation
   * @param encoding -  the encoding of the query string. If not specified then
   * the platform default encoding is used.
   * @return XdmValue - result of the the query as a XdmValue
   * @throws SaxonApiException
   */
  XdmValue *executeQueryToValue(const char *infilename, const char *query,
                                const char *encoding = nullptr);

  //! Perform the Query to a string representation.
  /**
   * @param infilename - The file name of the source document
   * @param query - The query as string representation
   * @param encoding -  the encoding of the query string. If not specified then
   * the platform default encoding is used.
   * @return char array - result of as a string
   * @throws SaxonApiException
   */
  const char *executeQueryToString(const char *infilename, const char *query,
                                   const char *encoding = nullptr);

  //! Execute the Query cached.
  /**
   * The use of the context item would have had to be set in advance
   * @return XdmValue of the result
   * @throws SaxonApiException
   *
   */
  XdmValue *runQueryToValue();

  /**
   * Execute the Query cached.
   * The use of the context item would have had to be set in advance
   * @return Result as a string (i.e. pointer array of char)
   * @throws SaxonApiException
   *
   */
  const char *runQueryToString();

  //! Execute the Query cached to file.
  /**
   * The use of the context item would have had to be set in advance
   * Assume the output filename has been set in advance
   * @throws SaxonApiException
   *
   */
  void runQueryToFile();

  //! Declare a namespace binding.
  /**
   * Declare a namespace binding as part of the static context for queries
   * compiled using this XQueryCompiler. This binding may be overridden by a
   * binding that appears in the query prolog. The namespace binding will form
   * part of the static context of the query, but it will not be copied into
   * result trees unless the prefix is actually used in an element or attribute
   * name.
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

  /**
   * Get a parameter value by name
   * @param name - Specified parameter name to get
   * @param withParam Internal use only
   * @return XdmValue
   */
  XdmValue *getParameter(const char *name, bool withParam=true);

  //! Get all parameters as a std::map
  /**
   * @return std::map  - map of the parameters string->XdmValue*
   */
  std::map<std::string, XdmValue *> &getParameters();

  //! Get all properties as a std::map
  /**
   * @return std::map map of the properties string->string
   */
  std::map<std::string, std::string> &getProperties();

  //! Compile a query supplied as a file name.
  /**
   * The supplied query is cached for later execution.
   */
  void setQueryFile(const char *filename);

  //! Compile a query supplied as a string.
  /**
   * The supplied query is cached for later execution.
   */
  void setQueryContent(const char *content);

  //! Set the static base URI for the query
  /**
   * @param baseURI the static base URI; or nullptr to indicate that no base URI
   * is available
   */
  void setQueryBaseURI(const char *baseURI);

  /**
   * set the current working directory
   */
  void setcwd(const char *cwd);

  //! Check for exception thrown.
  /**
   * @return char*. Returns the main exception message if thrown otherwise
   * return nullptr
   */
  const char *checkException();

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
   * A query may have a number of errors reported against it.
   * @return char* - The message of the exception
   */
  const char *getErrorMessage();

  //! Get the first error code if there are any errors
  /**
   * After the execution of the query there may be a number of errors reported
   * against it.
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
  bool streaming;
  std::string cwdXQ; /*!< current working directory */
  SaxonProcessor *proc;

  int64_t cppXQ;
  std::map<std::string, XdmValue *>
      parameters; /*!< map of parameters used for the query as (string, value)
                     pairs */
  std::map<std::string, std::string>
      properties; /*!< map of properties used for the query as (string, string)
                     pairs */
  SaxonApiException *exception;
};

#endif /* SAXON_XQUERY_H */
