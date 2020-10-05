/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_DeIdentify.sas                                                 */
/* Description:  De-Identify a study specified as input files                      */
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

libname sdtm     '<your path to input>';
libname sdtmdeid '<your path to output>';

options validvarname=upcase;
libname data (work);
%include 'di_ExternalData.sas';
filename odsout '.';

/* Read a selection of date formats into SAS dates */
proc format;
  invalue anydate
  19000101-99993112 = [yymmdd8.]
  other             = [anydtdte8.];
run;

%di_StudyMetadata;       /* Build metadata from PhUse and study data */

data _messages;          /* Collect messages */
  length data     $ 17   /* libname.memname  */
         variable $ 8    /* SDTM limitation  */
         category   8    /* Message groups   */
         message  $ 200; /* Keep text short  */
  stop;
run;

%di_offset_base;         /* Calculate base for offsetting dates etc  */

proc copy in=sdtm out=work;
run;

/* Study specific extra operations */
%di_remove_dsn(lib=work, mem=dvold);
%di_remove_dsn(lib=work, mem=suppdvold);
%di_remove_dsn(lib=work, mem=suppdv);
%di_remove_var(lib=work, mem=dm, var=country);
%di_remove_dsn(lib=work, mem=sc);
%di_offset(lib=work, mem=suppda, var=qval, cond=index(qlabel,'Date'));
%di_remove_obs(lib=work, mem=suppdm, cond=qnam='RACEOTH');
%di_remove_obs(lib=work, mem=suppdm, cond=qnam='REGION');
%di_remove_obs(lib=work, mem=supplb, cond=qnam='ESOCOMM');
%di_offset(lib=work, mem=suppsv, var=qval, cond=qnam='SCTCDTC');
%di_remove_obs(lib=work, mem=suppsv, cond=qnam='SVNOTC');
%di_remove_obs(lib=work, mem=suppxe, cond=qnam='XEREADIS');
%di_offset(lib=work, mem=suppxo, var=qval, cond=index(qlabel,'Date'));
%di_remove_var(lib=work, mem=xo, var=xostresc);

/* General operations */
filename deident catalog 'work.code.deident.source';

data _NULL_;
  set _StudyMetadata;
  file deident;
  put action +(-1) '(lib=work, mem=' memname +(-1) ', var=' name +(-1) ');';
run;

%include deident;

proc copy in=work out=sdtmdeid mtype=data;
  exclude _: con: cou: sdtm:;
run;

/* Done de-identifying, now reporting */

ods path work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);
proc template;
  define style styles.deidentify;
  parent=styles.default;
    replace Document from Container /
            htmldoctype =
            '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">'
            htmlcontenttype = 'text/html'
            protectspecialchars = off
            linkcolor = colors('link2')
            visitedlinkcolor = colors('link1');
  end;
run;

ods html file='DeIdentify.htm' style=deidentify path=odsout;
ods listing close;

title 'Issues handled during DE-identification';

proc sort data=_messages;
  by category message;
run;

proc report data=_messages missing center nowindows;
  by category;
  label category='Category';
  columns message;
  define  message / flow width=80 'Action taken';
run;

ods html close;
ods listing;
