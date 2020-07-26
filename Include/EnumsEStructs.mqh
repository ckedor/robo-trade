//+------------------------------------------------------------------+
//|                                                EnumsEStructs.mqh |
//|                                                  Christian Kedor |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Christian Kedor"
#property link      "https://www.mql5.com"

#define STOP_LOSS "Stop Loss"
#define TAKE_PROFIT_1 "Take Profit 1"
#define TAKE_PROFIT_2 "Take Profit 2"
#define REFERENCIA "Referencia"

#define CLR_COMPRA clrBlue
#define CLR_VENDA clrRed

enum REF 
{
   COMPRAR,
   VENDER,
   NDA
};

struct Referencia
{
   MqlRates candle;
   REF ref;  
};

struct ReferenciaSaida
{
   MqlRates candle;
   bool ativo;  
};

enum ESTRATEGIA1
{
   e91,
   e91Agressiva,
   nenhuma
};

enum ESTRATEGIA2
{
   e92,
   nenhuma
};