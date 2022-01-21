
/*
	!!!! NB : ALIMENTER LA CARTE AVANT DE CONNECTER L'USB !!!

VERSION 16/12/2021 :
- ToolboxNRJ V4
- Driver version 2021b (synchronisation de la mise à jour Rcy -CCR- avec la rampe)
- Validé Décembre 2021

*/


/*
STRUCTURE DES FICHIERS

COUCHE APPLI = Main_User.c : 
programme principal à modifier. Par défaut hacheur sur entrée +/-10V, sortie 1 PWM
Attention, sur la trottinette réelle, l'entrée se fait sur 3V3.
Attention, l'entrée se fait avec la poignée d'accélération qui va de 0.6V à 2.7V !

COUCHE SERVICE = Toolbox_NRJ_V4.c
Middleware qui configure tous les périphériques nécessaires, avec API "friendly"

COUCHE DRIVER =
clock.c : contient la fonction Clock_Configure() qui prépare le STM32. Lancée automatiquement à l'init IO
lib : bibliothèque qui gère les périphériques du STM : Drivers_STM32F103_107_Jan_2015_b
*/



#include "ToolBox_NRJ_v4.h"




//=================================================================================================================
// 					USER DEFINE
//=================================================================================================================





// Choix de la fréquence PWM (en kHz)
#define FPWM_Khz 20.0

#define T3 (0.0020)
#define T4 (0.0029)



						


//==========END USER DEFINE========================================================================================

// ========= Variable globales indispensables et déclarations fct d'IT ============================================

void IT_Principale(void);
//=================================================================================================================


/*=================================================================================================================
 					FONCTION MAIN : 
					NB : On veillera à allumer les diodes au niveau des E/S utilisée par le progamme. 
					
					EXEMPLE: Ce progamme permet de générer une PWM (Voie 1) à 20kHz dont le rapport cyclique se règle
					par le potentiomètre de "l'entrée Analogique +/-10V"
					Placer le cavalier sur la position "Pot."
					La mise à jour du rapport cyclique se fait à la fréquence 1kHz.

//=================================================================================================================*/


float Te,Te_us;

float a1,a0,b1,b0;

float k1,k0;

float coef = 3.3/4096.0;

float ft = 400.0;

float fe;


int main (void)
{
// !OBLIGATOIRE! //	
Conf_Generale_IO_Carte();	
	

	
// ------------- Discret, choix de Te -------------------	
fe = 6.0*ft;
Te=	1.0/fe; // en seconde
Te_us=Te*1000000.0; // conversion en µs pour utilisation dans la fonction d'init d'interruption
	

//______________ Ecrire ici toutes les CONFIGURATIONS des périphériques ________________________________	
// Paramétrage ADC pour entrée analogique
Conf_ADC();
// Configuration de la PWM avec une porteuse Triangle, voie 1 & 2 activée, inversion voie 2
Triangle (FPWM_Khz);
Active_Voie_PWM(1);	
Active_Voie_PWM(2);	
Inv_Voie(2);

Start_PWM;
R_Cyc_1(2048);  // positionnement à 50% par défaut de la PWM
R_Cyc_2(2048);

// Activation LED
LED_Courant_On;
LED_PWM_On;
LED_PWM_Aux_Off;
LED_Entree_10V_On;
LED_Entree_3V3_Off;
LED_Codeur_Off;

// Conf IT
Conf_IT_Principale_Systick(IT_Principale, Te_us);

// Calcul des elements du correcteur PI numerique 

a1 = (float)Te+(2.0*(float)T3);
a0 = (float)Te-(2.0*(float)T3);
b1 = 2.0*(float)T4;
b0 = -2.0*(float)T4;

k1 = (float)a1/(float)b1;
k0 = (float)a0/(float)b1;


while(1)
	{}

}





//=================================================================================================================
// 					FONCTION D'INTERRUPTION PRINCIPALE SYSTICK
//=================================================================================================================
int Courant_1,Cons_In;
float epsilon,sigma;
float duty_cycle;


float epsilon_prec = 0.0;
float sigma_prec = 0.0;

void IT_Principale(void)
{
 Cons_In=Entree_3V3();
 Courant_1=I1();
	
 //Calcul de l'erreur
	epsilon = (Cons_In-Courant_1)*coef;
	
	//Calcul de sigma
	sigma = k1*epsilon + k0*epsilon_prec + sigma_prec;
	
	//Borner sigma
	if(sigma < (-0.45)){
		
		sigma = -0.45;
		
	} else if (sigma > (0.45)){
		
		sigma = 0.45;
		
	}
	
	sigma_prec = sigma;
	epsilon_prec = epsilon;
	
	// Duty cycle
  duty_cycle = (sigma+0.5)*4096;
	
 R_Cyc_1((int)duty_cycle);
 R_Cyc_2((int)duty_cycle);
  
	
}

