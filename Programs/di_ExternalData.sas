/***********************************************************************************/
/* Project:      De-Identification                                                 */
/* Program Name: di_ExternalData.sas                                               */
/* Description:  Convert Excel data from PhUse into SAS datasets and obtain        */
/*               Country => Continent mapping from SAS system maps data            */
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

/* Get rule per SDTM variable and dataset */
proc import file='<your path>\PHUSE_STDM_redaction.xlsx'
             out=sdtmig replace dbms=excelcs;
  sheet='SDTMIG';
run;

/* Continents from SAS system map data */
proc sql;
  /* Join by ISONAME */
  create table countries1 as select distinct
         name,
         isoname,
         isoalpha2,
         isoalpha3,
         contnent
    from maps.names,
         maps.metamaps
   where names.isoname = metamaps.country;

  /* Join by NAME */
  create table countries2 as select distinct
         name,
         isoname,
         isoalpha2,
         isoalpha3,
         contnent
    from maps.names,
         maps.metamaps
   where names.name = metamaps.country;

  /* Collect all possible combinations */
  create table countries as select distinct *
    from countries1
   outer union corresponding select *
    from countries2;

  /* Correct known data errors */
  update countries
     set contnent = 92 where name = 'MEXICO'; /* Also registred as 93=Europe */

  update countries
     set contnent = 95 where name = 'RUSSIA';  /* Also registred as 93=Europe */
quit;

/* Remove duplicates */
proc sort data=countries out=country nodup;
  by contnent name;
run;

/* Combine continent and country codes */
proc sql;
  create table continent as select distinct
         isoalpha2,
         isoalpha3,
         propcase(metamaps.country) as continent label='Continent'
    from country,
         maps.metamaps (where=(id = 'CONT ID' and contnent ne .))
   where country.contnent = metamaps.contnent;
quit;
