//+----------------------------------------------------------------------------+
//|                                                         robo_trade.mq5    |
//|                                                         Christian Kedor    |
//|                                                         João Vitor Oliveira|
//+----------------------------------------------------------------------------+
#property copyright "Christian Kedor/ João Vitor Oliveira"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Include\FuncoesUteis.mqh"
#include "Include\ObjetosGraficos.mqh"
#include "Include\EnumsEStructs.mqh"
#include <Trade\Trade.mqh>
#include <ChartObjects\ChartObjectsTxtControls.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Panel.mqh>


/*========================================== Variáveis de Entrada ==========================================*\
\*==========================================================================================================*/         

input ENUM_TIMEFRAMES mm_periodo            = PERIOD_CURRENT; 
input ENUM_MA_METHOD mm_lenta_metodo        = MODE_SMA;     
input ENUM_MA_METHOD mm_rapida_metodo       = MODE_EMA; 
input ENUM_APPLIED_PRICE mm_preco           = PRICE_CLOSE; 

input ESTRATEGIA1 estrategia1               = e91;
input ESTRATEGIA2 estrategia2               = e92;

input int num_lots                          = 100;           
input string hora_limite_fecha_op           = "16:50";

/*=========================================== Variáveis Globais ============================================*\
\*==========================================================================================================*/ 

#define SETUP_91 "Setup 9.1"
#define SETUP_92 "Setup 9.2"
#define SETUP_91_AGR "Setup 9.1 Agr."

//Classes da biblioteca padrão
CTrade trade;
CDialog dialog;
CLabel label;
CLabel label2;
CPanel panel;
CAppDialog appdialog;
CObjetosGraficos grafico;
CChartObjectTrend trendline;


//Indicadores
int      mme9Handle; 
int      mma21Handle;
double   mme9[];   
double   mma21[];

//Dados históricos
MqlRates candles[];
MqlTick  tick;  

Referencia stRef;
ReferenciaSaida stRefSaida;

double tp1;
double tp2;
double sl;

/*=========================================== Funções Principais ===========================================*\
\*==========================================================================================================*/
int OnInit()
{
   mme9Handle  = iMA(_Symbol, mm_periodo, 9, 0, mm_rapida_metodo, mm_preco);
   mma21Handle = iMA(_Symbol, mm_periodo, 21, 0, mm_lenta_metodo, mm_preco);
 
   if(mme9Handle < 0 || mma21Handle < 0){
      Alert("Erro ao tentar criar Handles para o indicador - erro: ", GetLastError(), "!");
      return(-1);
   }
   
   trade.SetAsyncMode(false);
   
   SetBuffersInit(mme9Handle, mma21Handle, mme9, mma21, candles);
   ZeraRefs();
   

 
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   bool newCandle = NewCandle();
   bool operando = VerificaHorarioOperacao(TimeCurrent());
   bool posicionado = PositionSelect(_Symbol);
   
   //Pegar Dados Históricos
   SetBuffersOnTick(newCandle, mme9Handle, mma21Handle, mme9, mma21, candles, tick);
   
   if (NewDay(newCandle, candles)){
      grafico.DesenhaLinhaDia(TimeToString(TimeCurrent()), TimeCurrent());
      ZeraRefs();
   }
   
   if (!posicionado && operando){
      //Setup para compra
      if (newCandle){
         CalculaReferencia();
      }
      
      //Realizar Compra
      if (stRef.ref != NDA){
         
         if (stRef.ref == COMPRAR && tick.ask > stRef.candle.high){
            RealizarOrdemDeCompra();
         }
         else if(stRef.ref == VENDER && tick.ask < stRef.candle.low){
            RealizarOrdemDeVenda();
         }
      }
   }
   
   if (posicionado){
      
      if (!operando){
         EncerraPosicao();
      }
      else
      {
         if (newCandle){
            CalculaReferenciaSaida();
            grafico.DesenhaStops(sl, tp1, tp2, TimeCurrent());
         }
     
         //Comprado                                           
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            OperarComprado();
         }
         //Vendido
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            OperarVendido();
         } 
      }
   }  
}

void OnDeinit(const int reason)
{
   
   appdialog.Destroy(reason);
   IndicatorRelease(mme9Handle);
   IndicatorRelease(mma21Handle);
   
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   appdialog.ChartEvent(id, lparam, dparam, sparam);
   
   
   OnButtonClick(id, sparam);

}

void OnButtonClick(int _id, string _sparam){
   
   
   
//   if (_id == CHARTEVENT_OBJECT_CLICK){
//      bool pressed = ObjectGetInteger(0, "Button_1", OBJPROP_STATE);
//      
//      if(pressed && _sparam == "Button_1")
//      {
//         Print("O objeto clicado é o buton 1");
//      }
//
//   }

}

/*=========================================== Funções Auxiliares ===========================================*\
\*==========================================================================================================*/

void CalculaReferencia()
{
   if (estrategia1 == e91){
      if (IndicadorViraPraCima(mme9) && IndicadorMaiorQueIndicador(mme9, mma21)){
         SetaReferenciaCompra(SETUP_91);
      }
      else if (IndicadorViraPraBaixo(mme9) && IndicadorMenorQueIndicador(mme9, mma21)){
         SetaReferenciaVenda(SETUP_91);
      }
      else{
         stRef.ref = NDA;
      }
   }
   else if(estrategia1 == e91Agressiva){
      if (IndicadorViraPraCima(mme9) && IndicadorCaindo(mma21)) {
         SetaReferenciaCompra(SETUP_91_AGR);
      }
      else if (IndicadorViraPraBaixo(mme9) && IndicadorSubindo(mma21)){
         SetaReferenciaVenda(SETUP_91_AGR);
      }
      else{
         stRef.ref = NDA;
      }
   }
   
   if (estrategia2 == e92 && stRef.ref == NDA)
   {
      if (IndicadorSubindo(mme9) && IndicadorMaiorQueIndicador(mme9, mma21) && candles[1].close < MenorValorCloseOpen(candles[2])){
         SetaReferenciaCompra(SETUP_92);
      }
      else if (IndicadorCaindo(mme9) && IndicadorMenorQueIndicador(mme9, mma21) && candles[1].close > MaiorValorCloseOpen(candles[2])){
         SetaReferenciaVenda(SETUP_92);
      }
      else{
         stRef.ref = NDA;
      }
   }   
}

void SetaReferenciaCompra(string szEstrategia)
{          
   stRef.candle = candles[1];
   stRef.ref = COMPRAR;
   grafico.DesenhaLinhaReferencia(candles[1].time, candles[1].high, CLR_COMPRA);
   grafico.EscreveNaTela("Estrategia", CLR_COMPRA, szEstrategia, TimeCurrent() - _Period, candles[1].high + 3*_Point); 
}

void SetaReferenciaVenda(string szEstrategia)
{
   stRef.candle = candles[1];
   stRef.ref = VENDER;
   grafico.DesenhaLinhaReferencia(candles[1].time, candles[1].low, CLR_VENDA); 
   grafico.EscreveNaTela("Estrategia", CLR_VENDA, szEstrategia, TimeCurrent() - _Period, candles[1].low - 3*_Point);
}

void CalculaReferenciaSaida()
{ 
   if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
      if (IndicadorViraPraBaixo(mme9) && candles[1].close < mme9[1] && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
         stRefSaida.candle = candles[1];
         tp2 = stRefSaida.candle.low;
         stRefSaida.ativo = true;
      }
      else if (IndicadorViraPraCima(mme9)){
         stRefSaida.ativo = false;
      }
   }
   else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
      if (IndicadorViraPraCima(mme9) && candles[1].close > mme9[1] && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
         stRefSaida.candle = candles[1];
         tp2 = stRefSaida.candle.high;
         stRefSaida.ativo = true;
      }
      else if (IndicadorViraPraBaixo(mme9)){
         stRefSaida.ativo = false;
      }
   }
}

void OperarComprado()
{
   if( tick.ask > tp1 && PositionGetDouble(POSITION_VOLUME) == 200)
      FechaCompra(PositionGetDouble(POSITION_VOLUME)/2); 
   
   if (tick.ask <= tp2 && stRefSaida.ativo || tick.ask < sl){
      FechaCompra(PositionGetDouble(POSITION_VOLUME));
      stRefSaida.ativo = false; 
   }
}  

void OperarVendido()
{
   if( tick.ask < tp1 && PositionGetDouble(POSITION_VOLUME) == 200)
      FechaVenda(PositionGetDouble(POSITION_VOLUME)/2); 
   
   if (tick.ask >= tp2 && stRefSaida.ativo || tick.ask > sl){
      FechaVenda(PositionGetDouble(POSITION_VOLUME)); 
      stRefSaida.ativo = false;
   }
}

void EncerraPosicao()
{
   if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
         FechaCompra(PositionGetDouble(POSITION_VOLUME));
   }
   else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
         FechaVenda(PositionGetDouble(POSITION_VOLUME));
   }
}

void RealizarOrdemDeCompra()
{
   ResetLastError();
   trade.Buy(200, _Symbol, 0, 0, 0, "Compra a Mercado");
   sl = stRef.candle.low;
   tp1 = tick.ask*1.008;
   if (trade.ResultRetcode() == 1008 || trade.ResultRetcode() == 1009){
   }
   else{
      Print("Erro ao enviar ordem. Erro: ", GetLastError());
   }
}

void RealizarOrdemDeVenda()
{
   ResetLastError();
   trade.Sell(200, _Symbol, 0, 0, 0, "Venda a Mercado");
   sl = stRef.candle.high;
   tp1 = tick.bid*0.992;
   if (trade.ResultRetcode() == 1008 || trade.ResultRetcode() == 1009){
   }
   else{
      Print("Erro ao enviar ordem. Erro: ", GetLastError());
   }
}

void FechaCompra(int volume)
{
   ResetLastError();
   trade.Sell(volume, _Symbol, 0, 0, 0, "Compra fechada");
   if (trade.ResultRetcode() == 1008 || trade.ResultRetcode() == 1009){
   }
   else{
      Print("Erro ao enviar ordem. Erro: ", GetLastError());
   }
   ZeraRefs();
}

void FechaVenda(int volume)
{
   ResetLastError();
   trade.Buy(volume, _Symbol, 0, 0, 0, "Venda fechada");
   if (trade.ResultRetcode() == 1008 || trade.ResultRetcode() == 1009){
   }
   else{
      Print("Erro ao enviar ordem. Erro: ", GetLastError());
   }
   ZeraRefs();
}

void ZeraRefs(){
   stRef.ref = NDA;
   stRefSaida.ativo = false;
   tp1 = 0;
   tp2 = 0;
   sl = 0;
}



                
                  
















              