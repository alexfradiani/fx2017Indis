/**
 * Indicator for daily levels
 */
#property copyright   "2017, Alexander Fradiani"
#property link        "http://www.fradiani.com"
#property description "Daily Levels"
#property strict

#property indicator_chart_window

/**
 * Inputs
 */
input int GmtOffset = 3; // Timezone Offset. Be aware of year daylight changes

/** 
 * Globals
 */
double prevH, prevL, prevClose;
datetime lastRenderedTime, lastRenderedDay;

int OnInit(void) {
    lastRenderedTime = lastRenderedDay = Time[0];

    init_rendering();

    return (INIT_SUCCEEDED);
}

void init_rendering() {
    if (Period() <= PERIOD_H1) {
        drawDaySeparators();
        drawHL();
        draw00Levels();
        drawPivots();
    }

    // ATR - daily range references
    dailyRanges();
}

void cleanChart() {
    int len = ObjectsTotal();
    while (len > 0) {
        string name = ObjectName(0);
        if (!ObjectDelete(name))
            Print("could not delete: " + name + ". error: " + (string)GetLastError());

        len--;
    }
}

void dailyRanges() {
    // calculate in pipettes
    double atr3d = NormalizeDouble(iATR(NULL, PERIOD_D1, 3, 0) / Point, 0);
    double atr5d = NormalizeDouble(iATR(NULL, PERIOD_D1, 5, 0) / Point, 0);
    double atr15d = NormalizeDouble(iATR(NULL, PERIOD_D1, 15, 0) / Point, 0);

    string name = "ATRRange";
    string format = "ATR: [3D: %.0f]  -----  [5D: %.0f]  -----  [15D: %.0f]";
    string text = StringFormat(format, atr3d, atr5d, atr15d);
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 10);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
    
    ObjectSetString(0, name, OBJPROP_TEXT, text);
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

            // Print("timestr: " + timestr + ", drawing line at: " + (string)startTime);
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
    double s2 = pp - (prevH - prevL);

    double r3 = prevH + 2 * (pp - prevL);
    double s3 = prevL - 2 * (prevH - pp);

    // drawing the levels
    lineForPivot("PP", pp, clrWhite);

    int rcolor = 0xB7440D;
    int scolor = 0x7E7EFA;
    lineForPivot("R1", r1, rcolor);
    lineForPivot("R2", r2, rcolor);
    lineForPivot("R3", r3, rcolor);

    lineForPivot("S1", s1, scolor);
    lineForPivot("S2", s2, scolor);
    lineForPivot("S3", s3, scolor);
}

void lineForPivot(string name, double price, int _color) {
    ObjectCreate(0, name, OBJ_HLINE, 0, Time[0], price);
    ObjectSetInteger(0, name, OBJPROP_COLOR, _color);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
    // label text for R1
    string labelname = "pivotLabel_" + name;
    ObjectCreate(labelname, OBJ_TEXT, 0, Time[0], price);
    ObjectSetString(0, labelname, OBJPROP_TEXT, name);
    ObjectSetInteger(0, labelname, OBJPROP_ANCHOR, ANCHOR_UPPER);
}

void updateLabels() {
    int len = ObjectsTotal();
    for (int i = 0; i < len; i++) {
        string name = ObjectName(i);
        if (objIs(name, "pivotLabel")) {
            double price = ObjectGetDouble(0, name, OBJPROP_PRICE);
            if (!ObjectMove(0, name, 0, Time[0], price))
                Print("error moving: " + (string)GetLastError());
        }
    }
}

bool objIs(string name, string matcher) {
    string result[];
    ushort u_sep = StringGetCharacter("_", 0);
    StringSplit(name, u_sep, result);

    Print("result[0]: " + result[0] + " matcher: " + matcher);
    if (result[0] == matcher)
        return true;

    return false;
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

    // update labels to be always at the last bar
    if (Time[0] != lastRenderedTime) {
        updateLabels();

        lastRenderedTime = Time[0];
    }

    // reset indicator with a new day
    if (Time[0] - lastRenderedDay >= 20*60*60) {
        cleanChart();
        init_rendering();
    }

    return 0;
}

void OnDeinit(const int reason) {
    cleanChart();
}
