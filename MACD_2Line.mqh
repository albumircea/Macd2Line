//+------------------------------------------------------------------+
//|                                                   MACD_2Line.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include<Mircea/_profitpoint/Base/IndicatorBase.mqh>

#ifdef __MQL4__
#include <MovingAverages.mqh>
#endif
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMACD2LineParams: public CAppParams
 {
                     ObjectAttr(int, FastMACD);
                     ObjectAttr(int, SlowMACD);
                     ObjectAttr(int, SignalMACD);
                     ObjectAttr(ENUM_APPLIED_PRICE, AppliedPrice);
public:
 };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMACD2Line : public Indicator
 {

                     ObjectAttr(int, FastMACD);
                     ObjectAttr(int, SlowMACD);
                     ObjectAttr(int, SignalMACD);
                     ObjectAttr(ENUM_APPLIED_PRICE, AppliedPrice);

private:
  int                _macdHandle, _minRatesTotal;
  double             _extMainLine[];   //MACDLine   (Slow-Fast)
  double             _extSignalLine[]; //SignalLine (9 Period Ema of MACDLine)


  double             _macdHist[];      //MACD Hist  (MacdLine- SignalLine)

#ifdef __MQL4__
  double             _macdHistUp[], _macdHistDown[];
#endif

  double             _colorIndBuffer[];


public:

                     CMACD2Line(CMACD2LineParams* params)
    :                mFastMACD(params.GetFastMACD()),
                     mSlowMACD(params.GetSlowMACD()),
                     mSignalMACD(params.GetSignalMACD()),
                     mAppliedPrice(params.GetAppliedPrice())
   {


    _minRatesTotal = int(mSignalMACD + MathMax(mFastMACD, mSlowMACD));

#ifdef __MQL5__
    _macdHandle = iMACD(_Symbol, PERIOD_CURRENT, mFastMACD, mSlowMACD, mSignalMACD, mAppliedPrice);
    if(_macdHandle == INVALID_HANDLE)
      Fail("Failed to retrieve data from iMACD Indicator", INIT_FAILED, LOGGER_PREFIX_ERROR);
    SetIndexBuffer(2, _macdHist, INDICATOR_DATA);
    ArraySetAsSeries(_macdHist, true);
    SetIndexBuffer(3, _colorIndBuffer, INDICATOR_COLOR_INDEX);
    ArraySetAsSeries(_colorIndBuffer, true);
#endif

    IndicatorSetString(INDICATOR_SHORTNAME, App::__appShortName__);

    SetIndexBuffer(0, _extMainLine, INDICATOR_DATA);
    ArraySetAsSeries(_extMainLine, true);


    SetIndexBuffer(1, _extSignalLine, INDICATOR_DATA);
    ArraySetAsSeries(_extSignalLine, true);


#ifdef __MQL4__
    SetIndexBuffer(2, _macdHistUp, INDICATOR_DATA);
    ArraySetAsSeries(_macdHistUp, true);

    SetIndexBuffer(3, _macdHistDown, INDICATOR_DATA);
    ArraySetAsSeries(_macdHistDown, true);

    ArraySetAsSeries(_macdHist, true);
    PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, _minRatesTotal);


    SetIndexLabel(0, "MACD");
    SetIndexLabel(1, "Signal");
    SetIndexLabel(2, "Histogram");
    SetIndexLabel(4, "Histogram");
#endif

    //--- shifting the start of drawing of the indicator
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, _minRatesTotal);
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, _minRatesTotal);
    PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, _minRatesTotal);

    //--- determining the accuracy of the indicator values
    IndicatorSetInteger(INDICATOR_DIGITS, 0);
   }

  int                Main(const int totalCalc,// size of input time series
                          const int prevCalc,// bars handled in previous call
                          const datetime &time[],
                          const double &open[],
                          const double &high[],
                          const double &low[],
                          const double &close[],
                          const long &tickVolume[],
                          const long &volume[],
                          const int &spread[]) override;


#ifdef __MQL4__
  int                MainMql(const int totalCalc,
                             const int prevCalc,
                             const datetime &time[],
                             const double &open[],
                             const double &high[],
                             const double &low[],
                             const double &close[],
                             const long &tickVolume[],
                             const long &volume[],
                             const int &spread[]);
#endif

#ifdef __MQL5__
  int                MainMql(const int totalCalc,
                             const int prevCalc,
                             const datetime &time[],
                             const double &open[],
                             const double &high[],
                             const double &low[],
                             const double &close[],
                             const long &tickVolume[],
                             const long &volume[],
                             const int &spread[]);
#endif



 };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CMACD2Line::Main(const int totalCalc, const int prevCalc, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tickVolume[], const long &volume[], const int &spread[])
override
 {
  return MainMql(totalCalc, prevCalc, time, open, high, low, close, tickVolume, volume, spread);
 }
//+------------------------------------------------------------------+

#ifdef __MQL4__
int CMACD2Line::MainMql(const int totalCalc, const int prevCalc, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tickVolume[], const long &volume[], const int &spread[])
 {


  int barsCalculated = totalCalc;
  if(barsCalculated < totalCalc || totalCalc < _minRatesTotal)
    return 0;

  int toCopy, limit;

  if(prevCalc > totalCalc || prevCalc <= 0)
    limit = totalCalc - _minRatesTotal - 1;      // Starting index for calculation of all bars
  else
    limit = totalCalc - prevCalc;                // starting index for calculation of new bars only

  toCopy = limit + 1;


  double macdHistValue = 0;
//Main Line
  for(int bar = limit; bar >= 0 && !IsStopped(); bar--)
   {
    _extMainLine[bar] = iMACD(NULL, 0, mFastMACD, mSlowMACD, mSignalMACD, PRICE_CLOSE, MODE_MAIN, bar) / _Point;
    _extSignalLine[bar] = iMACD(NULL, 0, mFastMACD, mSlowMACD, mSignalMACD, PRICE_CLOSE, MODE_SIGNAL, bar) / _Point;
    macdHistValue = (_extMainLine[bar] - _extSignalLine[bar]);
    if(macdHistValue >= 0) //Histogram Bullish
     {
      _macdHistUp[bar] = macdHistValue;
      //_macdHistDown[bar] = 0;
     }
    if(macdHistValue < 0) //Histogram Bearish
     {
      _macdHistDown[bar] = macdHistValue;
      // _macdHistUp[bar] = 0;
     }

   }
  return totalCalc;
 }

#endif

#ifdef __MQL5__
int CMACD2Line::MainMql(const int totalCalc, const int prevCalc, const datetime & time[], const double & open[], const double & high[], const double & low[], const double & close[], const long & tickVolume[], const long & volume[], const int &spread[])
 {

  int barsCalculated = BarsCalculated(_macdHandle);
  if(barsCalculated < totalCalc || totalCalc < _minRatesTotal)
    return 0;

  int toCopy, limit;

  if(prevCalc > totalCalc || prevCalc <= 0)
    limit = totalCalc - _minRatesTotal - 1;      // Starting index for calculation of all bars
  else
    limit = totalCalc - prevCalc;                // starting index for calculation of new bars only

  toCopy = limit + 1;

  if(CopyBuffer(_macdHandle, MAIN_LINE, 0, toCopy, _extMainLine) <= 0)//--- copy newly appeared data in the arrays
   {
    Print("Getting MACDLine values has failed! Error ", GetLastError());
    return(0);
   }

  if(CopyBuffer(_macdHandle, SIGNAL_LINE, 0, toCopy, _extSignalLine) <= 0)//--- copy newly appeared data in the arrays
   {
    Print("Getting SignalLine values has failed! Error ", GetLastError());
    return(0);
   }


  for(int bar = limit; bar >= 0 && !IsStopped(); bar--)//--- main indicator calculation loop
   {
    _extMainLine[bar] /= _Point;
    _extSignalLine[bar] /= _Point;
    _macdHist[bar] = (_extMainLine[bar] - _extSignalLine[bar]);
   }

  if(prevCalc > totalCalc || prevCalc <= 0)
    limit--;


//--- Main loop of the Ind indicator coloring
  for(int bar = limit; bar >= 0 && !IsStopped(); bar--)
   {
    int clr = 2;
    if(_macdHist[bar] > 0) //Histogram Bullish
     {
      if(_macdHist[bar] > _macdHist[bar + 1])
        clr = 4;
      if(_macdHist[bar] < _macdHist[bar + 1])
        clr = 3;
     }
    if(_macdHist[bar] < 0) //Histogram Bearish
     {
      if(_macdHist[bar] < _macdHist[bar + 1])
        clr = 0;
      if(_macdHist[bar] > _macdHist[bar + 1])
        clr = 1;
     }
    _colorIndBuffer[bar] = clr;
   }

  return totalCalc;
 }
//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
