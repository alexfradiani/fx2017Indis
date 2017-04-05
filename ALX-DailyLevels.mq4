/**
 * Indicator for daily levels
 */
#property copyright   "2017, Alexander Fradiani"
#property link        "http://www.fradiani.com"
#property description "Daily Levels"
#property strict

#property indicator_chart_window
#property script_show_inputs

/**
 * Inputs
 */
input int GmtOffset = 2;

/** 
 * Globals
 */
double prevH, prevL, prevClose;

int OnInit(void) {
    drawDaySeparators();
    drawHL();
    draw00Levels();
    drawPivots();

    return (INIT_SUCCEEDED);
}

void drawDaySeparators() {
    // yyyy.mm.dd hh:mi
    datetime now = TimeCurrent();

    for (int i = 1; i <= 5; i++) {
        int dow = TimeDayOfWeek(now);
        // skipping weekends
        if (dow == 0 || dow == 6) {
            Print("skipping day " + (string)dow);
        }
        else {
            string y = (string)TimeYear(now);
            string m = (string)TimeMonth(now);
            string d = (string)TimeDay(now);
            string h = (string)(0 + GmtOffset);

            string timestr = y + "." + m + "." + d + " " + h + ":00";
            datetime startTime = StringToTime(timestr);

            Print("timestr: " + timestr + ", drawing line at: " + (string)startTime);
            string cname = "Day Start - line" + (string)i;
            
            if (!ObjectCreate(0, cname, OBJ_VLINE, 0 /*subwindow*/, startTime, 0)) {
                int errno =  GetLastError();
                if (errno == 4200)
                    Print("skipping: " + cname + " (already exists)");
                else {
                    Print(__FUNCTION__, ": failed to create a vertical line! Error code = ", 
                          GetLastError());

                    return;
                }
            }
            
            ObjectSetInteger(0, cname, OBJPROP_COLOR, 0x575757);
            ObjectSetInteger(0, cname, OBJPROP_STYLE, STYLE_DASH);
        }

        now = now - 24*60*60;
    }
}

void drawHL() {
    // number of shifts for a day
    int shifts = 1;
    int period = Period();
    if (period < PERIOD_D1)
        shifts = 24*60 / period;

    datetime now = TimeCurrent();
    string y = (string)TimeYear(now);
    string m = (string)TimeMonth(now);
    string d = (string)TimeDay(now);
    string h = (string)(0 + GmtOffset);

    // the beginning of current day
    string timestr = y + "." + m + "." + d + " " + h + ":00";
    datetime startTime = StringToTime(timestr);

    // the bar that starts the day
    int bar = iBarShift(NULL, 0, startTime);
    int highestBar = iHighest(NULL, 0, MODE_HIGH, shifts, bar);
    int lowestBar = iLowest(NULL, 0, MODE_LOW, shifts, bar);

    prevH = iHigh(NULL, 0, highestBar);
    prevL = iLow(NULL, 0, lowestBar);
    prevClose = iClose(NULL, 0, bar);
    Print("highs and lows: " + (string)prevH + " " + (string)prevL);
    
    // draw horizontal line for high price
    string name = "High_" + (string)TimeCurrent();
    ObjectCreate(0, name, OBJ_HLINE, 0, Time[0], prevH);
    ObjectSetInteger(0, name, OBJPROP_COLOR, 0x575757);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
    
    // label for  high price
    string labelname = "label" + name;
    ObjectCreate(labelname, OBJ_TEXT, 0, Time[highestBar], prevH);
    ObjectSetString(0, labelname, OBJPROP_TEXT, "PrevH");
    ObjectSetInteger(0, labelname, OBJPROP_ANCHOR, ANCHOR_LOWER);

    // draw horizontal line for low price
    name = "Low_" + (string)TimeCurrent();
    ObjectCreate(0, name, OBJ_HLINE, 0, Time[0], prevL);
    ObjectSetInteger(0, name, OBJPROP_COLOR, 0x575757);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);

    // label for low price
    labelname = "label" + name;
    ObjectCreate(labelname, OBJ_TEXT, 0, Time[lowestBar], prevL);
    ObjectSetString(0, labelname, OBJPROP_TEXT, "PrevL");
    ObjectSetInteger(0, labelname, OBJPROP_ANCHOR, ANCHOR_UPPER);
}

void draw00Levels() {
    int cut = Digits == 5? 2 : 0;

    for (int i = 0; i < 100; i++) {
        double priceUp = NormalizeDouble(Bid - i*1000*Point, cut);
        double priceDn = NormalizeDouble(Bid + i*1000*Point, cut);

        string name = "level_00_" + (string)priceUp;
        ObjectCreate(0, name, OBJ_HLINE, 0, Time[0], priceUp);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        name = "level_00_" + (string)priceDn;
        ObjectCreate(0, name, OBJ_HLINE, 0, Time[0], priceDn);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    }
}

void drawPivots() {
    double pp = (prevClose + prevH + prevL) / 3;
    
    double r1 = 2 * pp - prevL;
    double s1 = 2 * pp - prevH;

    double r2 = pp + prevH - prevL;
    double s2 = pp - prevH - prevL;

    double r3 = prevH + 2 * (pp - prevL);
    double s3 = prevL - 2 * (prevH - pp);

    // drawing the levels
    lineForPivot("R1", r1, 0x7E7EFA);
    lineForPivot("R2", r2, 0x7E7EFA);
    lineForPivot("R3", r3, 0x7E7EFA);

    lineForPivot("S1", s1, 0xB7440D);
    lineForPivot("S2", s2, 0xB7440D);
    lineForPivot("S3", s3, 0xB7440D);
}

void lineForPivot(string name, double price, int _color) {
    ObjectCreate(0, name, OBJ_HLINE, 0, Time[0], price);
    ObjectSetInteger(0, name, OBJPROP_COLOR, _color);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    // label text for R1
    string labelname = "label" + name;
    ObjectCreate(labelname, OBJ_TEXT, 0, Time[0], price);
    ObjectSetString(0, labelname, OBJPROP_TEXT, name);
    ObjectSetInteger(0, labelname, OBJPROP_ANCHOR, ANCHOR_UPPER);
}

void OnStart() {
    // ...
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {

    return 0;
}