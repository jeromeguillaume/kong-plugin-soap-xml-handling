////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 - 2023 Saxonica Limited.
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at http://mozilla.org/MPL/2.0/. This Source Code Form is
// "Incompatible With Secondary Licenses", as defined by the Mozilla Public
// License, v. 2.0.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef SAXON_SCHEMA_H
#define SAXON_SCHEMA_H

#include "SaxonProcessor.h"

#include <string>

class SaxonProcessor;
class XdmValue;
class XdmNode;
class XdmItem;

/*! A <code>SchemaValidator</code> represents a factory for validating instance
 * documents against a schema.
 */
class SchemaValidator {
public:
  //! Default constructor.
  /*!
   * Creates Schema Validator
   * @throws SaxonApiException
   */
  SchemaValidator();

  //! A constructor with a SaxonProcessor.
  /*!
   * The supplied processor should have license flag set to true for the Schema
   * Validator to operate.
   * @param proc - the SaxonProcessor
   * @param cwd - set the current working directory
   * @throws SaxonApiException
   */
  SchemaValidator(SaxonProcessor *proc, std::string cwd = "");

  //! Copy constructor.
  /*!
    Creates Schema Validator
  */
  SchemaValidator(const SchemaValidator &other);

  //! Destructor method. At the end of the program call the release() method to
  //! clear the JVM.
  ~SchemaValidator();

  //! The copy assignment= operator
  /*!
   * Create a copy of the SchemaValidator.
   * @param other - SchemaValidator object
   */
  SchemaValidator &operator=(const SchemaValidator &other);

  //! Set the Current working Directory
  /**
   * Set the current working directory for the Schema Validator
   * @param cwd  - Supplied working directory which replaces any set cwd. Ignore
   * if cwd is NULL.
   */
  void setcwd(const char *cwd);

  //! Register the schema from file name.
  /**
   * The schema components derived from this schema document are added to
   * the cache of schema components maintained by this SchemaManager
   * @param xsd - File name of the schema relative to the cwd or full path if
   * cwd is null. The document may be either a schema document in source XSD
   * format, or a compiled schema in Saxon-defined SCM format (as produced using
   * the method exportSchema)
   * @throws SaxonApiException
   */
  void registerSchemaFromFile(const char *xsd);

  //! Register the schema supplied as a string
  /**
   * @param schemaStr - The schema document supplied as a string
   * @param systemID - The system ID of the document supplied as a string
   * @throws SaxonApiException
   */
  void registerSchemaFromString(const char *schemaStr,
                                const char *systemID = nullptr);

  //! Register the schema supplied as an XDM Node Object
  /**
   * @param node - The schema document supplied as an XdmNode object
   * @throws SaxonApiException
   */
  void registerSchemaFromNode(XdmNode *node);

  //! Export a precompiled Schema Component Model containing all the components
  //! (except built-in components) that have been loaded by using the register
  //! methods.
  /**
   *
   * @param fileName - The file name where the exported schema will be stored
   * @throws SaxonApiException
   */
  void exportSchema(const char *fileName);

  //! Set the name of the output file that will be used by the validator.
  /**
   * @param outputFile the output file name for later use
   */
  void setOutputFile(const char *outputFile);

  //! Validate an instance document by a registered schema.
  /**
   *
   * @param sourceFile Name of the file to be validated. Allow nullptr when
   * source document is supplied with other method
   * @throws SaxonApiException
   */
  void validate(const char *sourceFile = nullptr);

  //! Validate an instance document supplied as a Source object
  /**
   * @param sourceFile The name of the file to be validated. Default is nullptr
   * @return XdmNode - the validated document returned to the calling program
   * @throws SaxonApiException
   */
  XdmNode *validateToNode(const char *sourceFile = nullptr);

  //! Set the source node for validation
  /**
   * @param source - The source document supplied as an XdmNode, which will be
   * used to validate against the schema using the validate methods.
   * The deletion of allocated memory associated with the source node is the
   * document is the responsbility of the caller.
   */
  void setSourceNode(XdmNode *source);

  //! Get the Validation report
  /**
   * The validation-report option must have been set to true in the properties
   * to use this feature.
   * @return XdmNode - Pointer to XdmNode. Return nullptr if validation
   * reporting feature has not been enabled
   * @throws SaxonApiException
   */
  XdmNode *getValidationReport();

  //! Set a parameter value used in the validator
  /**
   *
   *
   * @param name  of the parameter, as a string. For namespaced parameter use
   * the JAXP solution i.e. "{uri}name"
   * @param value of the query parameter, or nullptr to clear a previously set
   * value
   */
  void setParameter(const char *name, XdmValue *value);

  //! Remove a parameter (name, value) pair
  /**
   *
   *
   * @param name  of the parameter
   * @return bool - outcome of the removal
   */
  bool removeParameter(const char *name);

  //! Set a property.
  /**
   *
   *
   * @param name of the property
   * @param value of the property
   */
  void setProperty(const char *name, const char *value);
  //! Clear parameter values set.
  /**
   * Default behaviour (false) is to leave XdmValues in memory.
   * Individual pointers to XdmValue objects have to be deleted in the calling
   * program.
   *
   *  @param deleteValues - if true then XdmValues are deleted
   */
  void clearParameters(bool deleteValues = false);

  //! Clear property values set
  void clearProperties();

  /**
   * Get a parameter value by name
   * @param name - Specified parameter name to get
   * @param withParam Internal use only
   * @return XdmValue
   */
  XdmValue *getParameter(const char *name, bool withParam);


  //! Get all parameters as a std::map
  std::map<std::string, XdmValue *> &getParameters();

  //! Get all properties as a std::map
  std::map<std::string, std::string> &getProperties();

  //! Checks for pending exceptions without creating a local reference to the
  //! exception object
  /**
   *
   * @return bool - true when there is a pending exception; otherwise return
   * false
   */
  bool exceptionOccurred();

  //! Check for exception thrown.
  /**
   * @return char*. Returns the main exception message if thrown otherwise
   * return nullptr
   */
  const char *checkException();

  //! Clear any exception thrown
  void exceptionClear();

  //! Get number of errors during validation of the source against the schema
  /**
   * @return int - Count of the exceptions reported during validation
   */
  // int exceptionCount();

  //! Get the error message if there are any validation errors
  /**
   *  May have a number of validation errors reported against it the source.
   * @return char* - The message of the exception thrown
   */
  const char *getErrorMessage();

  //! Get error code if an error is reported
  /**
   * Validation error are reported as exceptions. All errors can be retrieved.
   * @return char* - The error code of the exception.
   */
  const char *getErrorCode();

  //! The validation mode may be either strict or lax.
  /**
   * The default is strict; this method may be called
   * to indicate that lax validation is required. With strict validation,
   * validation fails if no element declaration can be located for the outermost
   * element. With lax validation, the absence of an element declaration results
   * in the content being considered valid.
   * @param l -  true if validation is to be lax, false if it is to be strict
   */
  void setLax(bool l);

  //! Get the underlying java object of the C++ schema validator
  int64_t getUnderlyingValidator() { return cppV; }

private:
  bool lax; /*!< flag to indicate lax mode for the Schema validation */
  SaxonProcessor
      *proc; /*!< Saxon Processor Pointer, which created this SchemaValidator */
  // jclass  cppClass; /*!< JNI object where the SchemaValidator method will be
  // invoked */
  int64_t cppV;     /*!< The underlying SchemaValidator Java object */
  std::string cwdV; /*!< current working directory */
  std::string
      outputFile; /*!< The output file name for the exported schema validator */
  std::map<std::string, XdmValue *>
      parameters; /*!< map of parameters used for the transformation as (string,
                     value) pairs */
  std::map<std::string, std::string>
      properties; /*!< map of properties used for the transformation as (string,
                     string) pairs */
  SaxonApiException *exception; /*!< Exceptions reported against the
                                   SchemaValidator are stored here */
};

#endif /* SAXON_SCHEMA_H */
