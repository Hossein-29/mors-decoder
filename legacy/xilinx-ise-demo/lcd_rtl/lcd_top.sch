<?xml version="1.0" encoding="UTF-8"?>
<drawing version="7">
    <attr value="spartan3" name="DeviceFamilyName">
        <trait delete="all:0" />
        <trait editname="all:0" />
        <trait edittrait="all:0" />
    </attr>
    <netlist>
        <signal name="XLXN_21" />
        <signal name="XLXN_22" />
        <signal name="XLXN_23" />
        <signal name="XLXN_24" />
        <signal name="XLXN_25" />
        <signal name="XLXN_26" />
        <signal name="XLXN_36" />
        <signal name="XLXN_37" />
        <signal name="XLXN_38" />
        <signal name="GCLK" />
        <signal name="lcd_rw" />
        <signal name="lcd_e" />
        <signal name="data(7:0)" />
        <signal name="lcd_rs" />
        <signal name="LEDS(7:0)" />
        <signal name="SEG_SEL(4:0)" />
        <signal name="SEG_DATA(7:0)" />
        <signal name="rst_n" />
        <signal name="right_in_not" />
        <signal name="left_in_not" />
        <signal name="c_start_not" />
        <signal name="a_b_not" />
        <signal name="down_in_not" />
        <signal name="up_in_not" />
        <signal name="XLXN_20" />
        <signal name="XLXN_3" />
        <signal name="vga_hsync" />
        <signal name="vga_vsync" />
        <signal name="vga_green0" />
        <signal name="vga_green1" />
        <signal name="vga_red0" />
        <signal name="vga_red1" />
        <signal name="vga_blue0" />
        <signal name="vga_blue1" />
        <signal name="XLXN_65" />
        <signal name="XLXN_66" />
        <signal name="Buzzer" />
        <port polarity="Input" name="GCLK" />
        <port polarity="Output" name="lcd_rw" />
        <port polarity="Output" name="lcd_e" />
        <port polarity="Output" name="data(7:0)" />
        <port polarity="Output" name="lcd_rs" />
        <port polarity="Output" name="LEDS(7:0)" />
        <port polarity="Output" name="SEG_SEL(4:0)" />
        <port polarity="Output" name="SEG_DATA(7:0)" />
        <port polarity="Input" name="rst_n" />
        <port polarity="Input" name="right_in_not" />
        <port polarity="Input" name="left_in_not" />
        <port polarity="Input" name="c_start_not" />
        <port polarity="Input" name="a_b_not" />
        <port polarity="Input" name="down_in_not" />
        <port polarity="Input" name="up_in_not" />
        <port polarity="Output" name="vga_hsync" />
        <port polarity="Output" name="vga_vsync" />
        <port polarity="Output" name="vga_green0" />
        <port polarity="Output" name="vga_green1" />
        <port polarity="Output" name="vga_red0" />
        <port polarity="Output" name="vga_red1" />
        <port polarity="Output" name="vga_blue0" />
        <port polarity="Output" name="vga_blue1" />
        <port polarity="Output" name="Buzzer" />
        <blockdef name="div16">
            <timestamp>2011-5-20T22:35:47</timestamp>
            <rect width="256" x="64" y="-128" height="128" />
            <line x2="0" y1="-96" y2="-96" x1="64" />
            <line x2="0" y1="-32" y2="-32" x1="64" />
            <line x2="384" y1="-96" y2="-96" x1="320" />
        </blockdef>
        <blockdef name="lcd">
            <timestamp>2011-7-12T22:3:11</timestamp>
            <line x2="0" y1="-288" y2="-288" x1="64" />
            <line x2="0" y1="-32" y2="-32" x1="64" />
            <line x2="384" y1="-288" y2="-288" x1="320" />
            <line x2="384" y1="-224" y2="-224" x1="320" />
            <line x2="384" y1="-160" y2="-160" x1="320" />
            <rect width="64" x="320" y="-108" height="24" />
            <line x2="384" y1="-96" y2="-96" x1="320" />
            <rect width="256" x="64" y="-320" height="384" />
        </blockdef>
        <blockdef name="SevenSegTest">
            <timestamp>2011-12-2T19:52:39</timestamp>
            <line x2="0" y1="-352" y2="-352" x1="64" />
            <rect width="64" x="320" y="-364" height="24" />
            <line x2="384" y1="-352" y2="-352" x1="320" />
            <rect width="64" x="320" y="-108" height="24" />
            <line x2="384" y1="-96" y2="-96" x1="320" />
            <rect width="64" x="320" y="-44" height="24" />
            <line x2="384" y1="-32" y2="-32" x1="320" />
            <rect width="256" x="64" y="-384" height="396" />
            <line x2="0" y1="-192" y2="-192" x1="64" />
        </blockdef>
        <blockdef name="vga_pong_top">
            <timestamp>2011-12-2T19:23:12</timestamp>
            <rect width="352" x="64" y="-512" height="512" />
            <line x2="0" y1="-480" y2="-480" x1="64" />
            <line x2="0" y1="-416" y2="-416" x1="64" />
            <line x2="0" y1="-352" y2="-352" x1="64" />
            <line x2="0" y1="-288" y2="-288" x1="64" />
            <line x2="0" y1="-224" y2="-224" x1="64" />
            <line x2="0" y1="-160" y2="-160" x1="64" />
            <line x2="0" y1="-96" y2="-96" x1="64" />
            <line x2="0" y1="-32" y2="-32" x1="64" />
            <line x2="480" y1="-480" y2="-480" x1="416" />
            <line x2="480" y1="-160" y2="-160" x1="416" />
            <line x2="480" y1="-32" y2="-32" x1="416" />
            <line x2="480" y1="-80" y2="-80" x1="416" />
            <line x2="480" y1="-208" y2="-208" x1="416" />
            <line x2="480" y1="-432" y2="-432" x1="416" />
            <line x2="480" y1="-288" y2="-288" x1="416" />
            <line x2="480" y1="-336" y2="-336" x1="416" />
        </blockdef>
        <blockdef name="bufg">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="64" y1="-64" y2="0" x1="64" />
            <line x2="64" y1="-32" y2="-64" x1="128" />
            <line x2="128" y1="0" y2="-32" x1="64" />
            <line x2="128" y1="-32" y2="-32" x1="224" />
            <line x2="64" y1="-32" y2="-32" x1="0" />
        </blockdef>
        <blockdef name="inv">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="64" y1="-32" y2="-32" x1="0" />
            <line x2="160" y1="-32" y2="-32" x1="224" />
            <line x2="128" y1="-64" y2="-32" x1="64" />
            <line x2="64" y1="-32" y2="0" x1="128" />
            <line x2="64" y1="0" y2="-64" x1="64" />
            <circle r="16" cx="144" cy="-32" />
        </blockdef>
        <block symbolname="SevenSegTest" name="SEG_TEST">
            <blockpin signalname="GCLK" name="GCLK" />
            <blockpin signalname="LEDS(7:0)" name="LEDS(7:0)" />
            <blockpin signalname="SEG_SEL(4:0)" name="SEG_SEL(4:0)" />
            <blockpin signalname="SEG_DATA(7:0)" name="SEG_DATA(7:0)" />
            <blockpin signalname="rst_n" name="Reset" />
        </block>
        <block symbolname="bufg" name="XLXI_19">
            <blockpin signalname="GCLK" name="I" />
            <blockpin signalname="XLXN_20" name="O" />
        </block>
        <block symbolname="lcd" name="LCD_TEST">
            <blockpin signalname="XLXN_3" name="clk" />
            <blockpin signalname="rst_n" name="Reset" />
            <blockpin signalname="lcd_rs" name="lcd_rs" />
            <blockpin signalname="lcd_rw" name="lcd_rw" />
            <blockpin signalname="lcd_e" name="lcd_e" />
            <blockpin signalname="data(7:0)" name="data(7:0)" />
        </block>
        <block symbolname="vga_pong_top" name="VGA_GAME">
            <blockpin signalname="XLXN_20" name="clock40m" />
            <blockpin signalname="rst_n" name="reset" />
            <blockpin signalname="right_in_not" name="right_in_not" />
            <blockpin signalname="left_in_not" name="left_in_not" />
            <blockpin signalname="c_start_not" name="c_start_not" />
            <blockpin signalname="a_b_not" name="a_b_not" />
            <blockpin signalname="down_in_not" name="down_in_not" />
            <blockpin signalname="up_in_not" name="up_in_not" />
            <blockpin signalname="vga_hsync" name="vga_hsync" />
            <blockpin signalname="vga_red1" name="vga_red1" />
            <blockpin signalname="vga_blue1" name="vga_blue1" />
            <blockpin signalname="vga_blue0" name="vga_blue0" />
            <blockpin signalname="vga_red0" name="vga_red0" />
            <blockpin signalname="vga_vsync" name="vga_vsync" />
            <blockpin signalname="vga_green1" name="vga_green1" />
            <blockpin signalname="vga_green0" name="vga_green0" />
        </block>
        <block symbolname="div16" name="DIVIDER">
            <blockpin signalname="GCLK" name="clk" />
            <blockpin signalname="rst_n" name="rst" />
            <blockpin signalname="XLXN_3" name="clk_16" />
        </block>
        <block symbolname="inv" name="XLXI_27">
            <blockpin signalname="rst_n" name="I" />
            <blockpin signalname="Buzzer" name="O" />
        </block>
    </netlist>
    <sheet sheetnum="1" width="3520" height="2720">
        <branch name="GCLK">
            <wire x2="752" y1="624" y2="624" x1="480" />
            <wire x2="1408" y1="624" y2="624" x1="752" />
            <wire x2="752" y1="624" y2="1152" x1="752" />
            <wire x2="752" y1="1152" y2="1696" x1="752" />
            <wire x2="880" y1="1696" y2="1696" x1="752" />
            <wire x2="1008" y1="1152" y2="1152" x1="752" />
        </branch>
        <branch name="lcd_rw">
            <wire x2="1936" y1="1216" y2="1216" x1="1792" />
        </branch>
        <branch name="lcd_e">
            <wire x2="1936" y1="1280" y2="1280" x1="1792" />
        </branch>
        <branch name="data(7:0)">
            <wire x2="1936" y1="1344" y2="1344" x1="1792" />
        </branch>
        <branch name="lcd_rs">
            <wire x2="1936" y1="1152" y2="1152" x1="1792" />
        </branch>
        <instance x="1408" y="976" name="SEG_TEST" orien="R0">
            <attrtext style="fontsize:28;fontname:Arial" attrname="InstName" x="128" y="40" type="instance" />
        </instance>
        <branch name="LEDS(7:0)">
            <wire x2="1904" y1="624" y2="624" x1="1792" />
        </branch>
        <branch name="SEG_SEL(4:0)">
            <wire x2="1904" y1="880" y2="880" x1="1792" />
        </branch>
        <branch name="SEG_DATA(7:0)">
            <wire x2="1904" y1="944" y2="944" x1="1792" />
        </branch>
        <branch name="rst_n">
            <wire x2="512" y1="784" y2="784" x1="464" />
            <wire x2="512" y1="784" y2="1216" x1="512" />
            <wire x2="512" y1="1216" y2="1408" x1="512" />
            <wire x2="1408" y1="1408" y2="1408" x1="512" />
            <wire x2="512" y1="1408" y2="1760" x1="512" />
            <wire x2="512" y1="1760" y2="2400" x1="512" />
            <wire x2="880" y1="2400" y2="2400" x1="512" />
            <wire x2="1376" y1="1760" y2="1760" x1="512" />
            <wire x2="1008" y1="1216" y2="1216" x1="512" />
            <wire x2="1408" y1="784" y2="784" x1="512" />
        </branch>
        <branch name="right_in_not">
            <wire x2="1376" y1="1824" y2="1824" x1="1232" />
        </branch>
        <branch name="left_in_not">
            <wire x2="1376" y1="1888" y2="1888" x1="1232" />
        </branch>
        <branch name="c_start_not">
            <wire x2="1376" y1="1952" y2="1952" x1="1232" />
        </branch>
        <branch name="a_b_not">
            <wire x2="1376" y1="2016" y2="2016" x1="1232" />
        </branch>
        <branch name="down_in_not">
            <wire x2="1376" y1="2080" y2="2080" x1="1232" />
        </branch>
        <branch name="up_in_not">
            <wire x2="1376" y1="2144" y2="2144" x1="1232" />
        </branch>
        <instance x="880" y="1728" name="XLXI_19" orien="R0" />
        <branch name="XLXN_20">
            <wire x2="1376" y1="1696" y2="1696" x1="1104" />
        </branch>
        <instance x="1408" y="1440" name="LCD_TEST" orien="R0">
            <attrtext style="fontsize:28;fontname:Arial" attrname="InstName" x="96" y="88" type="instance" />
        </instance>
        <branch name="XLXN_3">
            <wire x2="1408" y1="1152" y2="1152" x1="1392" />
        </branch>
        <branch name="vga_hsync">
            <wire x2="1952" y1="1696" y2="1696" x1="1856" />
        </branch>
        <branch name="vga_vsync">
            <wire x2="1952" y1="1744" y2="1744" x1="1856" />
        </branch>
        <branch name="vga_green0">
            <wire x2="1952" y1="1840" y2="1840" x1="1856" />
        </branch>
        <branch name="vga_green1">
            <wire x2="1952" y1="1888" y2="1888" x1="1856" />
        </branch>
        <branch name="vga_red0">
            <wire x2="1952" y1="1968" y2="1968" x1="1856" />
        </branch>
        <branch name="vga_red1">
            <wire x2="1952" y1="2016" y2="2016" x1="1856" />
        </branch>
        <branch name="vga_blue0">
            <wire x2="1952" y1="2096" y2="2096" x1="1856" />
        </branch>
        <branch name="vga_blue1">
            <wire x2="1952" y1="2144" y2="2144" x1="1856" />
        </branch>
        <instance x="1376" y="2176" name="VGA_GAME" orien="R0">
            <attrtext style="fontsize:28;fontname:Arial" attrname="InstName" x="80" y="24" type="instance" />
        </instance>
        <instance x="1008" y="1248" name="DIVIDER" orien="R0">
            <attrtext style="fontsize:28;fontname:Arial" attrname="InstName" x="128" y="24" type="instance" />
        </instance>
        <iomarker fontsize="28" x="1904" y="880" name="SEG_SEL(4:0)" orien="R0" />
        <iomarker fontsize="28" x="1904" y="944" name="SEG_DATA(7:0)" orien="R0" />
        <iomarker fontsize="28" x="1904" y="624" name="LEDS(7:0)" orien="R0" />
        <iomarker fontsize="28" x="1232" y="1824" name="right_in_not" orien="R180" />
        <iomarker fontsize="28" x="1232" y="1888" name="left_in_not" orien="R180" />
        <iomarker fontsize="28" x="1232" y="1952" name="c_start_not" orien="R180" />
        <iomarker fontsize="28" x="1232" y="2016" name="a_b_not" orien="R180" />
        <iomarker fontsize="28" x="1232" y="2080" name="down_in_not" orien="R180" />
        <iomarker fontsize="28" x="1232" y="2144" name="up_in_not" orien="R180" />
        <iomarker fontsize="28" x="1936" y="1152" name="lcd_rs" orien="R0" />
        <iomarker fontsize="28" x="1936" y="1216" name="lcd_rw" orien="R0" />
        <iomarker fontsize="28" x="1936" y="1280" name="lcd_e" orien="R0" />
        <iomarker fontsize="28" x="1936" y="1344" name="data(7:0)" orien="R0" />
        <iomarker fontsize="28" x="1952" y="1696" name="vga_hsync" orien="R0" />
        <iomarker fontsize="28" x="1952" y="1744" name="vga_vsync" orien="R0" />
        <iomarker fontsize="28" x="1952" y="1840" name="vga_green0" orien="R0" />
        <iomarker fontsize="28" x="1952" y="1888" name="vga_green1" orien="R0" />
        <iomarker fontsize="28" x="1952" y="1968" name="vga_red0" orien="R0" />
        <iomarker fontsize="28" x="1952" y="2016" name="vga_red1" orien="R0" />
        <iomarker fontsize="28" x="1952" y="2096" name="vga_blue0" orien="R0" />
        <iomarker fontsize="28" x="1952" y="2144" name="vga_blue1" orien="R0" />
        <iomarker fontsize="28" x="464" y="784" name="rst_n" orien="R180" />
        <iomarker fontsize="28" x="480" y="624" name="GCLK" orien="R180" />
        <instance x="880" y="2432" name="XLXI_27" orien="R0" />
        <branch name="Buzzer">
            <wire x2="1120" y1="2400" y2="2400" x1="1104" />
            <wire x2="1952" y1="2400" y2="2400" x1="1120" />
        </branch>
        <iomarker fontsize="28" x="1952" y="2400" name="Buzzer" orien="R0" />
    </sheet>
</drawing>