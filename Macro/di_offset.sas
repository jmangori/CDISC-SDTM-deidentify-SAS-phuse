/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_offset.sas                                                     */
/* Description:  Offset dates to relative dates to study start                     */
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

%macro di_offset(lib=SDTM, mem=, var=, cond=1=1);
  %if (%sysfunc(libref(&lib))) %then %do;
    %put ERROR: Libname &lib not assigned;
    %return;
  %end;
  %if &mem= %then %return;
  %if &var= %then %return;
  %if %sysfunc(exist(&lib..&mem)) = 0 %then %return;

  %let dsid   = %sysfunc(open(&lib..&mem, i));
  %let varnum = %sysfunc(varnum( &dsid, &var));
  %let rc     = %sysfunc(close(&dsid));
  %if &varnum = 0 %then %return;

  proc sql;
    %if "&cond" = "1=1" %then %let msg = ;
    %else                     %let msg = where &cond;
    insert into _messages
       set data     = upcase("&mem"),
           variable = upcase("&var"),
           category = 2,
           message  = "Offsetting date variable %upcase(&var.) in dataset %upcase(&mem.) &msg";
  quit;

  data &lib..&mem.;
    set &lib..&mem;
    set _offset_base key=usubjid / unique;
    if &cond then do;
      if length(&var) > 10 and length(substr(&var, 1, 10)) = 10 then
        substr(&var, 1, 10) = put(input(substr(&var, 1, 10), anydate.) - offset, yymmdd10.);
      else if length(&var) = 7 then do;
        impdate = input(compress(&var || '-15'), yymmdd10.);
        &var = substr(put(impdate - offset, yymmdd10.), 1, 7);
      end;
      else if length(&var) = 4 then do;
        impdate = input(compress(&var || '-06-30'), yymmdd10.);
        &var = substr(put(impdate - offset, yymmdd10.), 1, 4);
      end;
    end;
    drop offset impdate;
  run;
%mend;

/*
data sv;
  set sdtm.sv;
  retain n 0;
  if usubjid in ('LP0041_21_10101_10' 'LP0041_21_10102_10' 'LP0041_21_11106_11');
  n + 1;
  if n = 10 then svstdtc = substr(svstdtc, 1, 7);
  if n = 20 then svendtc = substr(svendtc, 1, 4);
  drop n;
run;
%di_offset(lib=work, mem=sv, var=svstdtc);
%di_offset(lib=work, mem=sv, var=svendtc, cond=usubjid='LP0041_21_11106_11');
*/
