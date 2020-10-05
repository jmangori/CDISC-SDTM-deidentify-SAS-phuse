/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_offset_base.sas                                                */
/* Description:  Calculate base for offsetting dates etc                           */
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

%macro di_offset_base(lib=SDTM);
  %if (%sysfunc(libref(&lib))) %then %do;
    %put ERROR: Libname &lib not assigned;
    %return;
  %end;

  filename firsts catalog 'work.code.firsts.source';

  data _NULL_;
    set _StudyMetadata;
    where action ? 'offset' and name in ('RFSTDTC' 'SVSTDTC' 'DSSTDTC');
    file firsts;
    put 'proc sql;';
    put '  create table __subject_dates as select distinct';
    put '         "' memname +(-1) '" as memname length=8,';
    put '         "' name    +(-1) '" as name    length=8,';
    put '         usubjid,';
    put '         min(substr(' name +(-1) ', 1, 10)) as date length=10';
    put "    from &lib.." memname +(-1);
    if name = 'SVSTDTC' then
    put '   where visitnum = 1';
    if name = 'DSSTDTC' then
    put '   where dsdecod = "INFORMED CONSENT OBTAINED"';
    put '   group by usubjid';
    put '  having length(date) = 10;';
    put 'quit;';
    put 'proc append base=__first_dates data=__subject_dates;';
    put 'run;';
  run;

  %include firsts;

  proc sql noprint;
    select distinct min(input(substr(date, 1, 10), anydate.))
      into :studystart
      from __first_dates;
  quit;

  proc sort data=__first_dates nodup;
    by usubjid name;
  run;

  proc transpose data=__first_dates out=__references (drop=_:);
    by  usubjid;
    id  name;
    var date;
  run;

  data _offset_base;
    set __references;
    if rfstdtc = '' then rfstdtc = '9999-99-99';
    if svstdtc = '' then svstdtc = '9999-99-99';
    if dsstdtc = '' then dsstdtc = '9999-99-99';
    date = min(input(rfstdtc, anydate.), input(svstdtc, anydate.), input(dsstdtc, anydate.));
    offset = date - &studystart;
    /* For debugging only
    select (put(date, yymmdd10.));
      when (rfstdtc) refvar = 'RFSTDTC';
      when (svstdtc) refvar = 'SVSTDTC';
      when (dsstdtc) refvar = 'DSSTDTC';
      otherwise;
    end;
    format date yymmdd10.;
    */
    drop date;
    drop rfstdtc svstdtc dsstdtc;
  run;

  proc sql;
    create table _usubjid as select distinct
           '$usubjid' as fmtname,
           usubjid    as start,
           usubjid    as label
      from &lib..DM;
  quit;

  %di_recode(lib=work, mem=_usubjid, var=label);

  proc format cntlin=_usubjid;
  run;

  proc datasets lib=work nolist;
    delete _usubjid __:;
    run;

    modify _offset_base;
      index create usubjid / unique;
    run;
  quit;
%mend;

/*
%di_offset_base;
*/
