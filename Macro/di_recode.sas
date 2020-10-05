/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_recode.sas                                                     */
/* Description:  Generic recoding of any identifier based on the number of         */
/*               distinct values of same identifier                                */
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

%macro di_recode(lib=SDTM, mem=, var=, cond=1=1);
  %if (%sysfunc(libref(&lib))) %then %do;
    %put ERROR: Libname &lib not assigned;
    %return;
  %end;
  %if &mem= %then %return;
  %if &var= %then %return;
  %if %sysfunc(exist(&lib..&mem)) = 0 %then %return;

  %let dsid   = %sysfunc(open(&lib..&mem, i));
  %let varnum = %sysfunc(varnum( &dsid, &var));
  %let type   = %sysfunc(vartype(&dsid, &varnum)); /* Data type       */
  %let len    = %sysfunc(varlen( &dsid, &varnum)); /* Variable length */
  %let rc     = %sysfunc(close(&dsid));
  %if &varnum = 0 %then %return;
  %let len  = %sysfunc(min(&len, 32));

  proc sql noprint;
    /* Round up to next multiplum of 10 from number of distinct values */
    select distinct 10 ** length(strip(put(count(distinct &var), &len..)))
      into :offset
      from &lib..&mem;

    /* Obfuscate ID variable */
    create table __&mem._&var (drop=order) as select distinct
           &var.,
           %if &type = C %then md5(&var.);
           %else          left(md5(put(&var., &len..)));
           as order
      from &lib..&mem
     order by order;

    /* Assign new values as dull but quazi random sequence */
    create table __&mem._&var._new as select distinct
           &var,
           %if &type = C %then left(put(monotonic() + &offset, 32.));
           %else                        monotonic() + &offset;
           as new&var
      from __&mem._&var
     order by &var;

    /* Update values in situ */
    update &lib..&mem a
       set &var = (select distinct
                     %if &type = C %then put(new&var, $&len..);
                     %else new&var;
                     from __&mem._&var._new b
                    where a.&var = b.&var)
     where &var = (select distinct &var
                     from __&mem._&var._new c
                    where a.&var = c.&var)
       and &cond;
  quit;

  proc datasets lib=work nolist;
    delete __:;
    run;
  quit;
%mend;
/*
data test;
  idc = 'abcde';
  idn = 123;
  output;
  idc = 'fghij';
  idn = 45678;
  output;
run;
%di_recode(lib=work, mem=test, var=idc, cond=idc='abcde');
%di_recode(lib=work, mem=test, var=idn);
*/
