//+------------------------------------------------------------------+
//|                                                   Tendencias.mqh |
//|                                                  Christian Kedor |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Christian Kedor"
#property link      "https://www.mql5.com"

/*======================================= FUNÇOES TENDENCIAS MMS ===========================================*\
\*==========================================================================================================*/

bool IndicadorViraPraCima(double &indicador[]){ 
   return (indicador[1] > indicador[2] && indicador[3] > indicador[2]);
}

bool IndicadorViraPraBaixo(double &indicador[]){ 
   return (indicador[1] < indicador[2] && indicador[3] < indicador[2]);
}

bool IndicadorMaiorQueIndicador(double &indicador1[], double &indicador2[]){
   return (indicador1[1] > indicador2[1]);
}

bool IndicadorMenorQueIndicador(double &indicador1[], double &indicador2[]){
   return (indicador1[1] < indicador2[1]);
}

bool IndicadorSubindo(double &indicador[]){
   return (indicador[1] > indicador[2]);
}

bool IndicadorCaindo(double &indicador[]){
   return (indicador[1] < indicador[2]);
}

//Retorna o menor valor entre Close/Open de candle
double MenorValorCloseOpen(MqlRates &candle){
   
   if (candle.close < candle.open) 
      return candle.close;
   return candle.open;
    
}

//Retorna o maior valor entre Close/Open de candle
double MaiorValorCloseOpen(MqlRates &candle){
   
   if (candle.close > candle.open) 
      return candle.close;
   return candle.open; 
}