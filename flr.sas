/* $Id:$ */
%macro FLR(DSN);
    %put MHN-NOTE: Now running Field Length Report (FVR) v1.1;
    %local LIB MEM;
    %let LIB = %upcase( %scan( &DSN., 1, '.' ) );
    %let MEM = %upcase( %scan( &DSN., 2, '.' ) );

proc sql noprint;
    select name into :V separated by ' ' from dictionary.columns
        where upcase( libname ) = "&LIB." & upcase( memname ) = "&MEM." & upcase( type ) = 'CHAR';
    select length into :L separated by ' ' from dictionary.columns
        where upcase( libname ) = "&LIB." & upcase( memname ) = "&MEM." & upcase( type ) = 'CHAR';
    select left( put( count( * ), 5. ) ) into :N from dictionary.columns
        where upcase( libname ) = "&LIB." & upcase( memname ) = "&MEM." & upcase( type ) = 'CHAR';
quit;

data inspect( keep = _len_: );
    set &DSN.;
    array v{*} &V.;
    array l{*} _len_1 - _len_&N.;
    label %LenLab ;
    do i = 1 to dim( v );
        l{i} = length( trim( v{i} ) );
        end;
run;

title1 "Character Field Length Report for [&DSN.]";
proc means data = inspect n min max maxdec=0;
    var _len_:;
run;
%mend FLR;
%macro LenLab;
    %local C FLD LEN;
    %let C = 1;
    %let FLD = %scan( &V., &C., ' ' );
    %do %while(&FLD^=);
        %let LEN = %scan( &L., &C., ' ' );
        %bquote(_len_&C. = &FLD. - [&LEN.] )
        %let C = %eval( &C. + 1 );
        %let FLD = %scan( &V., &C., ' ' );
        %end;
%mend LenLab;
/* EOF Jack N Shoemaker (JShoemaker@TextureHealth.com) */
