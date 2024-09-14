#include <fstream>
#include <sstream>
#include <map>
#include <string.h>

#include <SaxonProcessor.h>
#include <XdmValue.h>
#include <XdmItem.h>
#include <XdmNode.h>
#include <XdmFunctionItem.h>
#include <DocumentBuilder.h>
#include <XdmMap.h>
#include <XdmArray.h>
#include <SchemaValidator.h>

#include <string>
#include <thread>

using namespace std;

typedef struct Context
{
  XsltExecutable *_xsltExecutable;
  std::string errMessage;
} Context;

// Format the Error message and Send it to stderr (ie. Kong Log)
void formatCerr(string msg, string detailedMsg)
{
  std::string tempStr;
  time_t timestamp = time(&timestamp);
  struct tm datetime = *localtime(&timestamp);
  char dateStr [64];

  sprintf (dateStr, "%d/%.2d/%.2d %.2d:%.2d:%.2d", datetime.tm_year + 1900, datetime.tm_mon + 1, datetime.tm_mday, datetime.tm_hour, datetime.tm_min, datetime.tm_sec);
  cerr << dateStr << " [error] " << "[libsaxon-4-kong.so]: " << msg;
  if (detailedMsg.size ())
  {
    if (detailedMsg.back () == '\n') {
      tempStr = detailedMsg.substr(0, detailedMsg.size () - 1);
    }
    else{
      tempStr = detailedMsg;
    }
    cerr << " " << tempStr;
  }
  cerr << endl;
}

extern "C" const char *getErrMessage( const void* context_void )
{
  const char *errMessage = nullptr;
  const Context *context = reinterpret_cast<const Context*>(context_void);
  
  if ( context != nullptr )
  {
    if ( context->errMessage.length()){
      errMessage = new char [context->errMessage.length() + 1];
      errMessage = context->errMessage.c_str();
    }
  }
  else{
    errMessage = strdup("The saxon Context is null");
  }

  return errMessage;
}

extern "C" void deleteContext( const void* context_void )
{
  const Context *context = reinterpret_cast<const Context*>(context_void);

  try {
    if (context != nullptr) {
      if (context->_xsltExecutable != nullptr){
        delete context->_xsltExecutable;
      }
      // DON'T DO 'delete context': il will be achieved by LuaJIT
    }
  }
  catch (...) {
    formatCerr ("Error deleting Context", "");
  }
}

extern "C" void *createSaxonProcessorKong ()
{
  SaxonProcessor *pSaxonProcessor = nullptr;
  try {
    // Initialize the SaxonC processor
    pSaxonProcessor = new SaxonProcessor(true);    
  }
  catch (...) {
    formatCerr ("Error in createSaxonProcessorKong", "");
  }

  return pSaxonProcessor;
}

extern "C" void *createXslt30ProcessorKong (const void * saxonProcessor_void, char **errMessage)
{
  Xslt30Processor *pXslt30Processor  = nullptr;
  try
  {
    SaxonProcessor *saxonProcessor = (SaxonProcessor *) saxonProcessor_void;
    pXslt30Processor = saxonProcessor->newXslt30Processor();
    *errMessage = nullptr;
  }
  catch (SaxonApiException& e) {
    formatCerr ("Error in createXslt30ProcessorKong", e.getMessage());
    *errMessage = strdup(e.getMessage());
  }
  catch (const std::exception& e) {
    formatCerr ("Error in createXslt30ProcessorKong", e.what());
    *errMessage = strdup(e.what());
  }
  return pXslt30Processor;
}

extern "C" void *compileStylesheet( const void *saxonProcessor_void, 
                                    const void *xslt30Processor_void,
                                    const char *stylesheet_string)
{
  Context *context = nullptr;
  
  try {
    Xslt30Processor *pxslt30Processor = (Xslt30Processor *) xslt30Processor_void;
    context = new Context();
    context->_xsltExecutable = pxslt30Processor->compileFromString(stylesheet_string);    
  }
  catch (SaxonApiException& e) {
    formatCerr ("Error in compile_stylesheet", e.getMessage());
    context->errMessage = e.getMessage();
  }
  catch (const std::exception& e) {
    formatCerr ("Error in compile_stylesheet", e.what());
    context->errMessage = e.what();
  }

  return context;
}

extern "C" const char *stylesheetInvokeTemplateKong(const void *saxonProcessor_void,
                                                    const void* context_void,
                                                    const char* template_name,
                                                    const char* param_name,
                                                    const char* param_value)
{
  const char* retval = nullptr;
  Context *context = nullptr;
  try
  {
    SaxonProcessor *saxonProcessor = (SaxonProcessor *) saxonProcessor_void;
    context = (Context*) context_void;
    map<string, XdmValue*> parameterValues;
    parameterValues[param_name] = saxonProcessor->makeStringValue(param_value);
    if ( context->_xsltExecutable != nullptr ){
      context->_xsltExecutable->setInitialTemplateParameters(parameterValues, false);
      const char* output_string = context->_xsltExecutable->callTemplateReturningString(template_name);
      if (output_string != nullptr) {
        // return free()able memory
        retval = strdup(output_string);
        delete output_string;
      }
    }
    else{
      throw std::runtime_error("The XSLT 3.0 Processor is null");
    }
  }
  catch (SaxonApiException& e) {
    formatCerr ("Error in stylesheetInvokeTemplateKong", e.getMessage());
    context->errMessage = e.getMessage();
  }
  catch (const std::exception& e) {
    formatCerr ("Error in stylesheetInvokeTemplateKong", e.what());
    context->errMessage = e.what();
  }
  
  return retval;
}


extern "C" const char* stylesheetTransformXmlKong( const void *saxonProcessor_void,
                                                   const void *context_void,
                                                   const char *xml_string)
{
  SaxonProcessor *saxonProcessor = (SaxonProcessor *) saxonProcessor_void;
  Context *context = nullptr;
  XdmNode *input = nullptr;
  const char* output_string = nullptr;
  const char* retval = nullptr;
  try{
    context = (Context*) context_void;
    XdmNode* input = saxonProcessor->parseXmlFromString(xml_string);
    if (input == nullptr) {
      throw std::runtime_error("parsing input XML failed");
    }
    output_string = context->_xsltExecutable->transformToString(input);
    delete input;
    if (output_string == nullptr) {
      throw std::runtime_error("parsing input XML failed");
    }
    retval = strdup(output_string);
  }
  catch (SaxonApiException& e) {
    formatCerr ("Error in stylesheetTransformXmlKong", e.getMessage());
    context->errMessage = e.getMessage();
  }
  catch (const std::exception& e) {
    formatCerr ("Error in stylesheetTransformXmlKong", e.what());
    context->errMessage = e.what();
  }
  
  if (output_string != nullptr){
    delete output_string;
  }
  // return free()able memory
  return retval;
}
