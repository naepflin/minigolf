int[][] EckTeil = {
{
383, 300, 
396, 405, 
312, 250
}, 
{
312, 250, 
396, 405, 
136, 351
}, 
{
120, 271, 
136, 351, 
87, 345
}, 
{
136, 351, 
396, 405, 
87, 345
}, 
{
87, 345, 
396, 405, 
104, 445
}, 
{
262, 500, 
104, 445, 
396, 405
}};


int[][] pilatus = {{144,680,155,330,262,507},{262,718,155,330,432,452},{432,663,155,330,446,386},{423,542,446,386,393,295},{378,477,393,295,360,302},{393,506,446,386,360,302},{349,285,360,302,304,278},{360,302,446,386,304,278},{304,278,446,386,283,30},{283,301,446,386,265,331},{446,386,155,330,265,331},{244,308,265,331,203,301},{203,301,265,331,191,326},{191,326,265,331,155,330}};

int[][] star = 
{{
266, 280, 
331, 352, 
248, 370
}, 
{
145, 317, 
248, 370, 
196, 414
}, 
{
248, 370, 
331, 352, 
196, 414
}, 
{
196, 414, 
331, 352, 
144, 489
}, 
{
144, 489, 
331, 352, 
228, 506
}, 
{
228, 506, 
331, 352, 
274, 442
}, 
{
274, 442, 
331, 352, 
289, 502
}, 
{
289, 502, 
331, 352, 
341, 416
}, 
{
377, 343, 
341, 416, 
331, 352
}};

int[][] wallBottomRight =
{{
239, 751, 
219, 748, 
241, 212
}, 
{
467, 211, 
241, 212, 
471, 191
}, 
{
471, 191, 
241, 212, 
220, 191
}, 
{
220, 191, 
241, 212, 
219, 748
}};

int[][] deflectorTopLeft =
{{
51, 168, 
50, 52, 
68, 113
}, 
{
68, 113, 
50, 52, 
81, 92
}, 
{
81, 92, 
50, 52, 
97, 79
}, 
{
97, 79, 
50, 52, 
127, 68
}, 
{
50, 52, 
178, 50, 
127, 68
}, 
{
178, 60, 
127, 68, 
178, 50
}};

int[][] realPilatus = {{55,752,54,702,470,755},{470,755,54,702,468,661},{468,661,54,702,451,649},{451,649,54,702,425,636},{425,636,54,702,402,627},{380,614,402,627,372,618},{402,627,54,702,372,618},{372,618,54,702,349,616},{349,616,54,702,331,605},{331,605,54,702,309,608},{309,608,54,702,300,603},{300,603,54,702,297,604},{297,604,54,702,294,599},{294,599,54,702,290,599},{290,599,54,702,287,595},{287,595,54,702,281,591},{281,591,54,702,277,591},{277,591,54,702,272,590},{272,590,54,702,265,593},{261,592,265,593,258,593},{255,589,258,593,245,601},{258,593,265,593,245,601},{265,593,54,702,245,601},{245,601,54,702,244,597},{241,597,244,597,235,598},{235,598,244,597,230,604},{244,597,54,702,230,604},{230,604,54,702,229,602},{229,602,54,702,221,600},{211,597,221,600,209,603},{221,600,54,702,209,603},{198,604,209,603,198,607},{198,607,209,603,191,614},{209,603,54,702,191,614},{179,619,191,614,160,632},{191,614,54,702,160,632},{160,632,54,702,157,630},{157,630,54,702,150,629},{150,629,54,702,138,635},{130,639,138,635,125,645},{138,635,54,702,125,645},{112,649,125,645,105,653},{105,653,125,645,98,662},{125,645,54,702,98,662},{98,662,54,702,97,657},{97,657,54,702,90,656},{90,656,54,702,74,661},{56,667,74,661,54,702}};

int[][] pilatusTriangle = {{219, 523, 55, 45,375, 58}};

int[][] diagonalProtectors = {{277,224,324,177,285,232},{324,177,333,185,285,232},{277,96,285,88,324,143},{285,88,333,135,324,143},{187,135,235,88,196,143},{235,88,243,96,196,143},{187,185,196,177,235,232},{196,177,243,224,235,232}};

int[][] fiveShape = {{474,47,466,57,53,50},{468,117,470,748,413,117},{413,117,470,748,413,161},{149,161,413,161,151,322},{151,322,413,161,179,307},{179,307,413,161,233,293},{233,293,413,161,292,291},{292,291,413,161,331,298},{331,298,413,161,385,341},{385,341,413,161,423,402},{423,402,413,161,431,456},{413,161,470,748,431,456},{431,456,470,748,422,514},{422,514,470,748,395,565},{395,565,470,748,356,614},{356,614,470,748,302,639},{470,748,54,747,302,639},{302,639,54,747,236,638},{236,638,54,747,159,603},{159,603,54,747,102,559},{54,747,53,50,102,559},{158,542,143,523,182,561},{182,561,143,523,212,576},{212,576,143,523,254,589},{254,589,143,523,310,585},{310,585,143,523,345,559},{345,559,143,523,370,521},{370,521,143,523,379,480},{379,480,143,523,378,431},{378,431,143,523,357,383},{357,383,143,523,316,355},{143,523,102,559,316,355},{316,355,102,559,257,350},{257,350,102,559,200,356},{200,356,102,559,152,390},{152,390,102,559,143,400},{143,400,102,559,101,399},{102,559,53,50,101,399},{101,399,53,50,102,114},{53,50,466,57,102,114},{413,115,102,114,466,57},{410,111,464,50,417,118},{467,118,417,118,464,50}};
