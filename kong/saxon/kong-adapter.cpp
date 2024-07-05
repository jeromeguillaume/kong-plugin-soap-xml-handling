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
  Xslt30Processor *_xslt30Processor;
  XsltExecutable *_xsltExecutable;    
} Context;

extern "C" void *createSaxonProcessorKong ()
{
  SaxonProcessor *pSaxonProcessor = nullptr;
  try {
    // Initialize the SaxonC processor
    pSaxonProcessor = new SaxonProcessor(true);
  }
  catch (...) {
    cerr << "** Saxon C++: Error in initialize_saxon" << endl;
  }
  return pSaxonProcessor;
}

extern "C" void *compileStylesheet( const void * saxonProcessor_void, 
                                    const char *stylesheet_string)
{
  Context *context = nullptr;
  try {
    context = new Context();
    SaxonProcessor *saxonProcessor = (SaxonProcessor *) saxonProcessor_void;
    context->_xslt30Processor = saxonProcessor->newXslt30Processor();
    context->_xsltExecutable = context->_xslt30Processor->compileFromString(stylesheet_string);
  }
  catch (SaxonApiException& e) {
    cerr << "** Saxon C++: Error in compile_stylesheet " << e.getMessage() << endl;
  }
  catch (...) {
    cerr << "** Saxon C++: Error in compile_stylesheet" << endl;
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
  try
  {
    SaxonProcessor *saxonProcessor = (SaxonProcessor *) saxonProcessor_void;
    const Context *context = reinterpret_cast<const Context*>(context_void);

    map<string, XdmValue*> parameterValues;
    parameterValues[param_name] = saxonProcessor->makeStringValue(param_value);

    context->_xsltExecutable->setInitialTemplateParameters(parameterValues, false);

    const char* output_string = context->_xsltExecutable->callTemplateReturningString(template_name);
    if (output_string != nullptr) {
      // return free()able memory
      cerr << "** Saxon C++: " << output_string << endl;
      retval = strdup(output_string);
      delete output_string;
      cerr << "** Saxon C++: " << retval << endl;
    }
  }
  catch (SaxonApiException& e) {
    cerr << "** Saxon C++: Error in stylesheetInvokeTemplateKong " << e.getMessage() << endl;
  }
  catch (...) {
    cerr << "** Saxon C++: Error in stylesheetInvokeTemplateKong" << endl;
  }
  
  return retval;
}