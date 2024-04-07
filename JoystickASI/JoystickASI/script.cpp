#include "pch.h"
#include "script.h"
#include <main.h>
#include <natives.h>
#include "Joystick.h"
#include <string>
#include <stdarg.h>

#define DEBUG true
#define AIRBREAK_SENSIBILITY 10000

// Initialisation des éléments nécessaire à l'exécution du script
void Script::Initialize() {

}

// Permet d'écrire du texte de debogage
void Script::DebugText(float x, float y, const char* str, ...) {
    if (!DEBUG) return;
    char buffer[1500] = { 0 };

    va_list args;
    va_start(args, str);
    vsnprintf(buffer, sizeof(buffer), str, args);
    va_end(args);

    UI::SET_TEXT_FONT(0);
    UI::SET_TEXT_SCALE(0.0, 0.50);
    UI::SET_TEXT_COLOUR(255, 0, 0, 255);
    UI::SET_TEXT_CENTRE(0);
    UI::SET_TEXT_DROPSHADOW(0, 0, 0, 0, 0);
    UI::SET_TEXT_EDGE(0, 0, 0, 0, 0);
    UI::_SET_TEXT_ENTRY((char*)"STRING");
    UI::_ADD_TEXT_COMPONENT_STRING((LPSTR)std::string(buffer).c_str());
    UI::_DRAW_TEXT(x, y);
}

// Fonction principal du thread "Script". Exécute une fonction indéfiniment
void Script::Run() {
    srand(GetTickCount());

    Joystick joy;
    JoystickData inputData;

    BOOL reversedThrust = false;

    DWORD lastCheck = GetTickCount();
    DWORD lastReverseCheck = GetTickCount();

    // J'attend qu'un Joystick soit connecté
    while (true) {
        if (joy.IsJoystickInitialized()) {
            DebugText(0.9, 0.2, "Waiting Joystick ...");
        }
        else {
            DebugText(0.9, 0.2, "DirectInput is not initialized !");
        }

        // Je tente une connexion toute les 100 ms
        if ((GetTickCount() - lastCheck) > 100) {
            joy.ConnectJoystick();
            lastCheck = GetTickCount();
        }
        
        while (joy.IsJoystickInitialized() && joy.IsJoystickConnected()) {
            // Si il y a une erreur lors de la lecture, alors je coupe la communication avec le Joystick. Sinon je lit simplement les données
            if (FAILED(joy.GetInput(&inputData))) {
                joy.UnconnectJoystick();
                break;
            }

            // TODO: Faire en sorte que l'avion tourne bien !

            Ped currentPlayer = PLAYER::GET_PLAYER_PED((Player)-1);
            if (currentPlayer == 0) {
                DebugText(0.9, 0.2, "Player not found. (%i)", currentPlayer);
                continue;
            }

            // Vérifie si le joueur est bien dans un appareil aérien
            if (!PED::IS_PED_IN_ANY_PLANE(currentPlayer) && !PED::IS_PED_IN_ANY_HELI(currentPlayer)) {
                DebugText(0.9, 0.2, "Waiting for Plane ...");
                WAIT(0);
                continue;
            }

            // Pitch
            // Si le joystick est abaissé vers le bas
            if (inputData.pitch > (MAX_DIRECTION_VALUE / 2)) {
                // INPUT_VEH_FLY_PITCH_UD
                float pitchup = (float)(inputData.pitch - (MAX_DIRECTION_VALUE / 2)) / (float)(MAX_DIRECTION_VALUE / 2);
                CONTROLS::_SET_CONTROL_NORMAL(0, 110, pitchup);
                DebugText(0.9, 0.25, "PITCH UP: %f", pitchup);
            }
            // Si le joystick est remonté vers le haut
            else if (inputData.pitch < (MAX_DIRECTION_VALUE / 2)) {
                // INPUT_VEH_FLY_PITCH_UD
                float pitchdown = 1.0f - ((float)inputData.pitch / (float)(MAX_DIRECTION_VALUE / 2));
                CONTROLS::_SET_CONTROL_NORMAL(0, 110, -1.0f * pitchdown);
                DebugText(0.9, 0.25, "PITCH DOWN: %f", pitchdown);
            }

            // Roll
            // Si le joystick est vers la droite
            if (inputData.roll > (MAX_DIRECTION_VALUE / 2)) {
                // INPUT_VEH_FLY_ROLL_LR
                float rolld = (float)(inputData.roll - (MAX_DIRECTION_VALUE / 2)) / (float)(MAX_DIRECTION_VALUE / 2);
                CONTROLS::_SET_CONTROL_NORMAL(0, 107, rolld);
                DebugText(0.9, 0.3, "ROLL RIGHT: %f", rolld);
            }
            // Si le joystick est remonté vers le haut
            else if (inputData.roll < (MAX_DIRECTION_VALUE / 2)) {
                // INPUT_VEH_FLY_ROLL_LR
                float rollg = -1.0f * (1.0f - ((float)inputData.roll / (float)(MAX_DIRECTION_VALUE / 2)));
                CONTROLS::_SET_CONTROL_NORMAL(0, 107, rollg);
                DebugText(0.9, 0.3, "ROLL LEFT: %f", rollg);
            }

            // Yaw
            // Si le joystick est vers la droite
            if (inputData.yaw > (MAX_DIRECTION_VALUE / 2)) {
                // INPUT_VEH_FLY_ROLL_RIGHT_ONLY
                float yawd = (float)(inputData.yaw - (MAX_DIRECTION_VALUE / 2)) / (float)(MAX_DIRECTION_VALUE / 2);
                CONTROLS::_SET_CONTROL_NORMAL(0, 90, yawd);
                DebugText(0.9, 0.35, "YAW RIGHT: %f", yawd);
            }
            // Si le joystick est remonté vers le haut
            else if (inputData.yaw < (MAX_DIRECTION_VALUE / 2)) {
                // INPUT_VEH_FLY_YAW_LEFT
                float yawg = 1.0f - ((float)inputData.yaw / (float)(MAX_DIRECTION_VALUE / 2));
                CONTROLS::_SET_CONTROL_NORMAL(0, 89, yawg);
                DebugText(0.9, 0.35, "YAW LEFT: %f", yawg);
            }

            // Throttle (Calcul de la sensibilité nécessaire)
            // Accélération
            if (inputData.power > 0) { 
                float throttleu = (float)(inputData.power) / (float)(MAX_DIRECTION_VALUE);

                if (reversedThrust) {
                    // INPUT_VEH_FLY_THROTTLE_DOWN
                    CONTROLS::_SET_CONTROL_NORMAL(0, 88, throttleu);
                    DebugText(0.9, 0.4, "THROTTLE (Reverse): %f", throttleu);
                }
                else {
                    // INPUT_VEH_FLY_THROTTLE_UP
                    CONTROLS::_SET_CONTROL_NORMAL(0, 87, throttleu);
                    DebugText(0.9, 0.4, "THROTTLE: %f", throttleu);
                }

            }

            // Bouton de tir (de test)
            if (inputData.fireButton) {
                CONTROLS::_SET_CONTROL_NORMAL(0, 114, 1.0f);
                DebugText(0.9, 0.45, "FIRE");
            }

            // Bouton de reverse
            if (inputData.reverseButton) {
                if ((GetTickCount() - lastReverseCheck) > 200) {
                    reversedThrust = ~reversedThrust;
                    lastReverseCheck = GetTickCount();
                }
            }

            // Bouton de "Airbreak"
            if (inputData.airbreakButton) {
                CONTROLS::_SET_CONTROL_NORMAL(0, 88, 0.5f);
                DebugText(0.9, 0.5, "AIRBREAK");
            }




           
            WAIT(0);
        }

        WAIT(1);
    }

    delete& joy;
}