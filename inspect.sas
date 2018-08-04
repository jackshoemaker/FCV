/* $Id:$ */
%macro Inspect(LIB=,_TABLES=,TYPE=SQL);
    %local FCVDEST MVRDEST C TOKEN;

    %let C = 1;
    %let TOKEN = %scan( &_TABLES., &C., ' ' );
    %do %while( "&TOKEN." ^= "" );
        %if %upcase("&TYPE.") = "SQL" %then %do;
            title1 "[&SERVER..&DB..&LIB..&TOKEN.]";
            %let FCVDEST = &OUT.\FCV\&SERVER.\FCV.&DB..&LIB..&TOKEN..&_..pdf;
            %let MVRDEST = &OUT.\FCV\&SERVER.\MVR.&DB..&LIB..&TOKEN..&_..pdf;
            run;
            %end;
        %else %do;
            title1 "[&LIB..&TOKEN.]";
            %let FCVDEST = &OUT.\FCV\FCV.&LIB..&TOKEN..&_..pdf;
            %let MVRDEST = &OUT.\FCV\MVR.&LIB..&TOKEN..&_..pdf;
            %end;
        %miss_report(LIB=&LIB.,MEM=&TOKEN.,REPORT=&MVRDEST.);
        ods pdf notoc style = mhn file = "&FCVDEST.";
        %NumerFCV(LIB=&LIB.,MEM=&TOKEN.);
        %AlphaFCV(LIB=&LIB.,MEM=&TOKEN.);
        ods pdf close;
        run;
        %let C = %eval( &C. + 1 );
        %let TOKEN = %scan( &_TABLES., &C., ' ' );
        %end;
%mend Inspect;
/* EOF Jack N Shoemaker (JShoemaker@TextureHealth.com) */
