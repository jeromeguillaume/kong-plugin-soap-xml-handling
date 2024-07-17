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
         cerr << "** Saxon C++: delete _xsltExecutable:" << context->_xsltExecutable << endl;
        delete context->_xsltExecutable;
      }
      cerr << "** Saxon C++: delete context" << endl;
      delete context;
    }
  }
  catch (...) {
    cerr << "** Saxon C++: Error deleting Context" << endl;
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
    cerr << "** Saxon C++: Error in createSaxonProcessorKong" << endl;
  }
  return pSaxonProcessor;
}

extern "C" void *createXslt30ProcessorKong (const void * saxonProcessor_void)
{
  Xslt30Processor *pXslt30Processor  = nullptr;
  try
  {
    SaxonProcessor *saxonProcessor = (SaxonProcessor *) saxonProcessor_void;
    pXslt30Processor = saxonProcessor->newXslt30Processor();
  }
  catch (SaxonApiException& e) {
    cerr << "** Saxon C++: Error in createXslt30ProcessorKong " << e.getMessage() << endl;
  }
  catch (const std::exception& e) {
    cerr << "** Saxon C++: Error in createXslt30ProcessorKong " << e.what() << endl;
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
    cerr << "** Saxon C++: _xsltExecutable: " << context->_xsltExecutable << endl;
  }
  catch (SaxonApiException& e) {
    cerr << "** Saxon C++: Error in compile_stylesheet " << e.getMessage() << endl;
    context->errMessage = e.getMessage();
  }
  catch (const std::exception& e) {
    cerr << "** Saxon C++: Error in compile_stylesheet" << e.what() << endl;
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
    if ( context->_xsltExecutable !=nullptr ){
      cerr << "** Saxon C++: _xsltExecutable: " << context->_xsltExecutable << endl;
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
    cerr << "** Saxon C++: Error in stylesheetInvokeTemplateKong " << e.getMessage() << endl;
    context->errMessage = e.getMessage();
  }
  catch (const std::exception& e) {
    cerr << "** Saxon C++: Error in stylesheetInvokeTemplateKong " << e.what() << endl;
    context->errMessage = e.what();
  }
  
  return retval;
}