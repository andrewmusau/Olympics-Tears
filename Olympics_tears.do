import excel "C:\Users\amus\Desktop\Alex New\Olympics_data.xls", sheet("Data") firstrow clear
//DEFINE VALUE LABELS
lab define female 0 "Male" 1 "Female"
lab define prevgold 0 "none" 1 "One or more"
lab define london 0 "Rio 2016" 1 "London 2012"
lab define medcer 0  "cried_end" 1 "cried_med"
lab define continent 1 "Africa" 2 "Asia" 3 "Europe" 4 "N. America" 5 "Oceania" 6 "S. America"
replace CONTINENT= "N. America" if CONTINENT== "North America"
replace CONTINENT= "S. America" if CONTINENT== "South America"
lab define when 0 "before end of event" 1 "at end of event" 2 "after end of event"
lab define highlights 0 "Full coverage" 1 "Highlights"

//ENCODE STRING VARIABLES SPECIFYING VALUE LABELS
foreach var of varlist FEMALE PREVGOLD LONDON MEDCER CONTINENT WHEN HIGHLIGHTS{
	rename `var' `=lower("`var'")'
    encode  `=lower("`var'")', g(`var') label( `=lower("`var'")')
	drop  `=lower("`var'")'
}
//CREATE CORRELATION TABLE IN PAPER (TABLE 3)
*ssc install estout replace // DELETE ASTERISK IF NOT INSTALLED
capture program drop mkcorrlbls
program define mkcorrlbls, rclass
    local vars: coleq e(b)
    local vars: list uniq vars
    local eqlabels
    local coeflabels
    local i 0
    foreach v of local vars {
        local ++i
        local eqlabels `eqlabels' (`i')
        local coeflabels `coeflabels' `v' "(`i') `v'"
    }
    return local eqlabels `eqlabels'
    return local coeflabels `coeflabels'
end

estpost corr AGE FEMALE PREVGOLD DOPED LONDON MEDCER HOST CRIEDEND LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA EUROPE N_AMERICA OCEANIA S_AMERICA, matrix
mkcorrlbls
esttab . using corrtable.txt, replace b(3) unstack nonum nomtitle not noobs compress varwidth(12) ///
    eqlabels(`r(eqlabels)', lhs("Variables")) ///
    coeflabels(`r(coeflabels)') 
	
//ESTIMATIONS FOR TABLE 4 IN PAPER
qui logit CRIED AGE FEMALE PREVGOLD DOPED LONDON MEDCER HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA, cluster(MED_ID)
g sample = e(sample)
margins, dydx(*) post
est sto m1

qui logit CRIED AGE PREVGOLD DOPED LONDON MEDCER HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA if FEMALE, cluster(MED_ID)
margins, dydx(*) post
est sto m2

qui logit CRIED AGE PREVGOLD DOPED LONDON MEDCER HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA if !FEMALE, cluster(MED_ID)
margins, dydx(*) post
est sto m3

qui logit CRIED AGE FEMALE PREVGOLD DOPED LONDON HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA i.WHEN if !MEDCER
margins, dydx(*) post
est sto m4

qui logit CRIED AGE FEMALE PREVGOLD DOPED LONDON HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA i.WHEN HIGHLIGHTS if !MEDCER
margins, dydx(*) post
est sto m5

qui logit CRIED AGE FEMALE PREVGOLD DOPED LONDON HOST CRIEDEND LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA if MEDCER
margins, dydx(*) post
est sto m6

//THE RESULTING RTF FILE NEEDS ADDITIONAL FORMATTING
local hook "\deflang1033\plain\fs24"
local pfmt "\paperw15840\paperh12240\landscape" // US letter
esttab m* using table4.rtf, replace b(3) aux(p) nobaselevels nostar wide subs(N_AM "N AM" S_AM "S AM" (.) "" "`hook'" "`hook'`pfmt'" (0.000) "{\i p} < .001" (0. "{\i p} = . " ) "" 0.000 "") 

//ESTIMATIONS FOR TABLE 5 IN PAPER

//TIMECRIED IS RIGHT CENSORED (0/ MISSING). REPLACE MISSING WITH MAXIMUM OBSERVED DURATION + 1 SECOND FOR TOBIT
qui sum TIMECRIED
replace TIMECRIED= int(`r(max)')+ 1 if missing(TIMECRIED)

eststo k1: tobit TIMECRIED AGE FEMALE PREVGOLD DOPED LONDON MEDCER HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA, vce(cluster MED_ID) ul(109)

eststo k2: tobit TIMECRIED AGE PREVGOLD DOPED LONDON MEDCER HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA if FEMALE, vce(cluster MED_ID) ul(109)

eststo k3: tobit TIMECRIED AGE PREVGOLD DOPED LONDON MEDCER HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA if !FEMALE, vce(cluster MED_ID) ul(109)

eststo k4: tobit TIMECRIED  AGE FEMALE PREVGOLD DOPED LONDON HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA i.WHEN if !MEDCER, ul(109)

eststo k5: tobit TIMECRIED  AGE FEMALE PREVGOLD DOPED LONDON HOST LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA i.WHEN HIGHLIGHTS if !MEDCER, ul(109)

eststo k6: tobit TIMECRIED AGE FEMALE PREVGOLD DOPED LONDON HOST CRIEDEND LGDPC EF LF RF LFPF LFPM SPW AFRICA ASIA N_AMERICA OCEANIA S_AMERICA if MEDCER, ul(109)

//THE RESULTING RTF FILE NEEDS ADDITIONAL FORMATTING
local hook "\deflang1033\plain\fs24"
local pfmt "\paperw15840\paperh12240\landscape" // US letter
esttab k* using table5.rtf, replace b(2)  aux(p 3) nobaselevels nostar wide subs(N_AM "N AM" S_AM "S AM" (.) "" "`hook'" "`hook'`pfmt'" (0.000) "{\i p} < .001" (0. "{\i p} = . " ) "" 0.000 "")  eqlabel(none) mlabel(none) keep(TIMECRIED:) coeflabel(_cons "Intercept")

//FIGURE 1
preserve
local j 1
forval i=1/6{
	count if !FEMALE & CONTINENT==`i'
    local n`j'= `r(N)'
	local++j
    count if FEMALE & CONTINENT==`i'
    local n`j'= `r(N)'
	local ++j
}
bys CONTINENT FEMALE: egen percent=total(CRIED)
bys CONTINENT FEMALE: replace percent= (percent/_N)*100

bys CONTINENT FEMALE percent: keep if _n==1
separate percent, by(FEMALE) veryshortlabel

//DEFINE BAR LABEL POSITIONS IN GRAPH
foreach i of numlist 1 2 11 12{
local pos`i'= `n`i''
}
forval i=3/8{
local pos`i'= `n`=`i'+2''
di "`pos`i''"
}
forval i=9/10{
local pos`i'= `n`=`i'-6''
}

gr bar percent?, over(CONTINENT, sort(1)) ytitle("") ysc(r(., 55) lstyle(none)) ylabel(,nogrid) scheme(s1mono) bar(1, blcolor(black) bfcolor(black*0.3)) bar(2, blcolor(navy) bfcolor(navy*0.3)) blab(total, format(%2.0f) size(vsmall)) ytitle("Percent") leg(order(1 "Male" 2 "Female") position(11) nobox region(lstyle(none)) cols(1) ring(0)bplacement(nw)) ysc(off)

local nb=`.Graph.plotregion1.barlabels.arrnels'
forval i=1/`nb' {
  local val = "`.Graph.plotregion1.barlabels[`i'].text[1]'"
  .Graph.plotregion1.barlabels[`i'].text[1]="({it:n=`pos`i''})"
  .Graph.plotregion1.barlabels[`i'].text[2]="`val'%" 
}
.Graph.drawgraph
restore

//TABLE 1
preserve
keep if sample
separate CRIED, by(MEDCER)
bys MED_ID (CRIED0): replace CRIED0= CRIED0[1] 
bys MED_ID (CRIED1): replace CRIED1 = CRIED1[1] 
bys MED_ID: keep if _n==1

bys COUNTRY: egen CriedEnd= total(CRIED0)
bys COUNTRY: egen CriedMed= total(CRIED1)
bys COUNTRY: g Gold= _N
bys COUNTRY: keep if _n==1

//THE RESULTING RTF FILE NEEDS ADDITIONAL FORMATTING
local hook "\deflang1033\plain\fs24"
local pfmt "\paperw15840\paperh12240\landscape" // US letter
estpost tabstat EF LF RF LFPF LFPM SPW Gold CriedEnd CriedMed, by(COUNTRY)
esttab . using table1.rtf, replace cells("EF LF RF LFPF LFPM SPW Gold CriedEnd CriedMed") ///
    noobs nomtitle nonumber varlabels(`e(labels)') varwidth(30) collab(, lhs("Country")) ///
	    drop(Total) subs("`hook'" "`hook'`pfmt'") 