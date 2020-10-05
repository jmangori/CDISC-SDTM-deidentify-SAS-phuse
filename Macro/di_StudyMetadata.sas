/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_StudyMetadata.sas                                              */
/* Description:  Build metadata for a specific study                               */
/***********************************************************************************/
/*  Copyright (c) 2020 Jørgen Mangor Iversen                                       */
/*                                                                                 */
/*  Permission is hereby granted, free of charge, to any person obtaining a copy   */
/*  of this software and associated documentation files (the "Software"), to deal  */
/*  in the Software without restriction, including without limitation the rights   */
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      */
/*  copies of the Software, and to permit persons to whom the Software is          */
/*  furnished to do so, subject to the following conditions:                       */
/*                                                                                 */
/*  The above copyright notice and this permission notice shall be included in all */
/*  copies or substantial portions of the Software.                                */
/*                                                                                 */
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     */
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       */
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    */
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         */
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  */
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  */
/*  SOFTWARE.                                                                      */
/***********************************************************************************/

%macro di_StudyMetadata(lib=SDTM);
options validvarname=upcase;

%if (%sysfunc(libref(&lib))) %then %do;
  %put ERROR: Libname &lib not assigned;
  %return;
%end;

/* Translate de-identification rules to macro calls */
proc format;
  value $rules
  'Remove dataset'                                          = '%di_remove_dsn'
  'Derive Age'                                              = '%di_derive_age'
  'Offset'                                                  = '%di_offset'
  'Elevate to continent'                                    = '%di_continent'
  'Recode subject ID'                                       = '%di_recode_subject'
  'Recode ID variable'                                      = '%di_recode_id'
  'Remove'                                                  = '%di_remove_var'
  'Keep'                                                    = '%di_keep'
  'No further de-identification'                            = '%di_no_further'
  'Review and only redact values with personal information' = '%di_manual'
  other                                                     = '';

  invalue rules
  '%di_remove_dsn'     = 1
  '%di_derive_age'     = 2
  '%di_offset'         = 3
  '%di_continent'      = 4
  '%di_recode_subject' = 5
  '%di_recode_id'      = 6
  '%di_remove_var'     = 7
  '%di_keep'           = 9
  '%di_no_further'     = 8
  '%di_manual'         = 10
  other                = 99;
run;

proc sql;
  /* Variables across all datasets */
  create table _global_vars as select distinct
         a.libname,
         a.memname,
         a.name,
         put(b.di_primary_rule, $rules.) as action
    from dictionary.columns a
   inner join data.sdtmig  b
      on a.name = b.variable_name
   where b.di_primary_rule ne ''
     and substr(b.variable_name, 1, 2) ne '--'
     and upcase(libname) = "&lib"
     and upcase(domain_prefix) = '';

  /* Variables for particular domains */
  create table _domain_vars as select distinct
         a.libname,
         a.memname,
         a.name,
         put(b.di_primary_rule, $rules.) as action
    from dictionary.columns a
   inner join data.sdtmig  b
      on a.name = b.variable_name
     and a.memname = b.domain_prefix
   where b.di_primary_rule ne ''
     and substr(b.variable_name, 1, 2) ne '--'
     and upcase(libname) = "&lib";

  /* All study domains except SUPP-- domains */
  create table _domains as select distinct
         memname as domain
    from dictionary.tables
   where upcase(libname) = "&lib"
     and upcase(substr(memname, 1, 4)) ne 'SUPP';

  /* List of variables per domain */
  create table _variables as select distinct
         compress(domain || substr(variable_name, 3)) as variable_name,
         di_primary_rule
    from data.sdtmig,
         _domains
   where di_primary_rule ne ''
     and substr(variable_name, 1, 2) = '--';

  /* General domain variables */
  create table _local_vars as select distinct
         a.libname,
         a.memname,
         a.name,
         put(b.di_primary_rule, $rules.) as action
    from dictionary.columns a
   inner join _variables    b
      on a.name = b.variable_name
   where upcase(libname) = "&lib";
quit;

/* What needs to be done at which variable */
data _rules;
  merge _global_vars _domain_vars _local_vars;
  by memname name;
  order = input(action, rules.);
run;

proc sort data=_rules out=StudyMetadata;
  by order libname memname name;
run;

proc datasets lib=work nolist;
  delete _:;
  run;

  change StudyMetadata=_StudyMetadata;
quit;

%mend;
