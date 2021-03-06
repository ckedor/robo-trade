//+------------------------------------------------------------------+
//|                                                      Include.mqh |
//|                                                  Christian Kedor |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Christian Kedor"
#property link      "https://www.mql5.com"

#include "Tendencias.mqh"

/*=========================================== FUNÇOES UTEIS =================================================*\
\*===========================================================================================================*/


/*============================================================================*\   
   Função: setBuffersInit()

Descrição:
  Entrada: 
           
           
    Saida:
\*============================================================================*/
void SetBuffersInit(int &mmRapidaHandle, int &mmLentaHandle, double &mmRapida[], double &mmLenta[], MqlRates &velas[]){

   CopyBuffer(mmRapidaHandle, 0, 0, 10, mmRapida);          //MA Rápida
   CopyBuffer(mmLentaHandle, 0, 0, 10, mmLenta);           //Ma Lenta
   CopyRates(_Symbol, _Period, 0, 4, velas);               //Dados de Velas
   
   ArraySetAsSeries(velas,true); 
   ArraySetAsSeries(mmRapida, true);
   ArraySetAsSeries(mmLenta, true);
}

/*============================================================================*\   
   Função: SetBuffersOnTick()

Descrição:
  Entrada: 
           
           
    Saida:
\*============================================================================*/
void SetBuffersOnTick(bool newCandle, int &mmRapidaHandle, int &mmLentaHandle, double &mmRapida[], double &mmLenta[], MqlRates &velas[], MqlTick &currentTick){

   SymbolInfoTick(_Symbol, currentTick);

   if (newCandle){
      CopyBuffer(mmRapidaHandle, 0, 0, 10, mmRapida);         //MA Rápida
      CopyBuffer(mmLentaHandle, 0, 0, 10, mmLenta);           //Ma Lenta
      CopyRates(_Symbol, _Period, 0, 4, velas);               //Dados de Velas
   }
}

/*============================================================================*\   
   Função: newCandle()

Descrição:
  Entrada: 
           
           
    Saida:
\*============================================================================*/
bool NewCandle()
{
   static datetime lastCandleTime = 0;
   datetime currentCandleTime = (datetime) SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   
   if (lastCandleTime == 0)
   {
      lastCandleTime = currentCandleTime;
      return false;
   }
   
   if(lastCandleTime != currentCandleTime)
   {
      lastCandleTime = currentCandleTime;
      return(true);
   }
   
   return(false);
}

/*============================================================================*\   
   Função: newCandle()

Descrição:
  Entrada: 
           
           
    Saida:
\*============================================================================*/
bool VerificaHorarioOperacao(datetime currentTime) {
  
   bool podeOperar = true;
   MqlDateTime stDatetimeAtual;
   TimeToStruct(currentTime, stDatetimeAtual);
   if (stDatetimeAtual.hour == 10 && stDatetimeAtual.min < 10 || 
       stDatetimeAtual.hour == 17 && stDatetimeAtual.min >= 40){
      podeOperar = false;
   }
   return podeOperar;
}

/*============================================================================*\   
   Função: newCandle()

Descrição:
  Entrada: 
           
           
    Saida:
\*============================================================================*/
bool NewDay(bool novaVela, MqlRates &velas[]){
 
   if (novaVela){
      
      MqlDateTime stCurrentTime;
      TimeToStruct(velas[0].time, stCurrentTime);
      MqlDateTime stLastTime;
      TimeToStruct(velas[1].time, stLastTime);
      int horaAtual = stCurrentTime.hour;
      int horaAnterior = stLastTime.hour;
      return horaAnterior > horaAtual;
   }  
   return false;
}