VAR
    // ==========================================
    // IEȘIRI (Scriem în OIP)
    // ==========================================
    conveyor_1       : BOOL;       
    speed_tag_1      : REAL := 0.5;
    conveyor_2       : BOOL;       
    speed_tag_2      : REAL := 0.5;
    lamp_tag         : BOOL;       

    run_tag_curved   : BOOL;
    speed_tag_curved : REAL := 0.8;

    run_tag_flex     : BOOL;
    speed_tag_flex   : REAL := 1.0; // Viteza maxima pentru role
    full_tag_flex    : BOOL;       

    lamp_biskit_tag_1 : INT;
    lamp_biskit_tag_2 : INT;

    enable_tag_turn   : BOOL;
    target_angle_turn : REAL := 90.0; 
    speed_tag_turn    : REAL := 0.5;
    
    muting_lamp_tag_conveyor : BOOL;
    release_tag_flex         : BOOL; 

    // ==========================================
    // INTRĂRI (Citim din OIP)
    // ==========================================
    out_button             : BOOL;       
    distance_tag           : REAL;       
    presence_tag_photo_eye : BOOL; 
    light_final_conveyor   : BOOL;  
    light_pallet           : BOOL;  
    done_tag_turn          : BOOL;  
    
    conveyor_run_1         : BOOL;       
    run_conveyor_2         : BOOL;       
    running_tag_curved     : BOOL;    

    // ==========================================
    // VARIABILE INTERNE
    // ==========================================
    sistem_pornit      : BOOL;
    ciclu_terminat     : BOOL; 
    obiect_detectat    : BOOL;       
    cutie_la_foto      : BOOL;       
    
    Timer_Banda1    : TON; 
    Timer_Banda2    : TON;
    
    Timp_Asteptare  : TIME := T#3S; 
    
    Citire_Feedback : BOOL; 
END_VAR

// ==========================================
// LOGICA DE CONTROL
// ==========================================

// 1. PORNIREA SISTEMULUI
IF out_button AND NOT sistem_pornit AND NOT ciclu_terminat THEN
    sistem_pornit := TRUE;
    ciclu_terminat := FALSE;
    obiect_detectat := FALSE;
    cutie_la_foto := FALSE;
    lamp_biskit_tag_1 := 0;
    lamp_biskit_tag_2 := 0;
END_IF;

// 2. DETECȚII
IF (distance_tag > 0.0) AND (distance_tag < 1.2) AND sistem_pornit THEN
    obiect_detectat := TRUE;
END_IF;

IF presence_tag_photo_eye AND sistem_pornit THEN
    cutie_la_foto := TRUE;
    lamp_biskit_tag_1 := 1;
    lamp_biskit_tag_2 := 1;
END_IF;

// 3. TIMERE (Pentru benzile 1 si 2)
Timer_Banda1(IN := obiect_detectat AND sistem_pornit, PT := Timp_Asteptare);
Timer_Banda2(IN := cutie_la_foto AND sistem_pornit, PT := Timp_Asteptare);

// 4. CONTROL BENZI 1 SI 2
IF sistem_pornit AND NOT Timer_Banda1.Q THEN
    conveyor_1 := TRUE; speed_tag_1 := 0.5;
ELSE
    conveyor_1 := FALSE;
END_IF;

IF sistem_pornit AND obiect_detectat AND NOT Timer_Banda2.Q THEN
    conveyor_2 := TRUE; speed_tag_2 := 0.5;
ELSE
    conveyor_2 := FALSE;
END_IF;

// 5. CONVEYOR CURBAT SI FLEX CONVEYOR
// Aici am legat ambele benzi sa porneasca imediat ce cutia a trecut de senzorul foto
// SAU daca senzorul din capatul curbei (light_final_conveyor) este atins.
IF sistem_pornit AND (cutie_la_foto OR light_final_conveyor) THEN
    run_tag_curved := TRUE; speed_tag_curved := 0.8;
    
    run_tag_flex := TRUE; speed_tag_flex := 1.0;
    release_tag_flex := TRUE; // Fortam rolele sa dea drumul cutiei
    full_tag_flex := FALSE;   // Spunem ca nu e plin
ELSE
    run_tag_curved := FALSE;
    run_tag_flex := FALSE;
END_IF;

// 6. TURNTABLE
// Turntable-ul se roteste cand senzorul din capatul curbei este atins
IF sistem_pornit AND light_final_conveyor THEN
    enable_tag_turn := TRUE;
    target_angle_turn := 90.0; 
    speed_tag_turn := 0.5;
END_IF;

// 7. FINALIZAREA TOTALĂ (Cand trece ultimul senzor de la paleti)
IF light_pallet AND sistem_pornit THEN
    sistem_pornit := FALSE;
    ciclu_terminat := TRUE;
END_IF;


// ==========================================
// REZOLVAREA ERORILOR DE WIRING
// ==========================================

Citire_Feedback := conveyor_run_1 AND run_conveyor_2 AND running_tag_curved;
muting_lamp_tag_conveyor := light_final_conveyor AND sistem_pornit;
lamp_tag := sistem_pornit;

// Oprim motoarele când ciclul s-a terminat (sau cand apesi pe Unforce)
IF NOT sistem_pornit THEN
    speed_tag_1 := 0.0;
    speed_tag_2 := 0.0;
    speed_tag_curved := 0.0;
    speed_tag_flex := 0.0;
    speed_tag_turn := 0.0;
    conveyor_1 := FALSE;
    conveyor_2 := FALSE;
    run_tag_curved := FALSE;
    run_tag_flex := FALSE;
    enable_tag_turn := FALSE;
END_IF;