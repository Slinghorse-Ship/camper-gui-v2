import QtQuick

// Canvas translation of the current v2 prototype SVG symbol library plus its Lucide navigation set.
Canvas {
    id: icon

    property string kind: "home"
    property color lineColor: "#59caff"
    property real strokeWidth: 2

    onKindChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function line(ctx, points) {
        ctx.beginPath();
        ctx.moveTo(points[0][0], points[0][1]);
        for (let index = 1; index < points.length; ++index)
            ctx.lineTo(points[index][0], points[index][1]);
        ctx.stroke();
    }

    function circle(ctx, cx, cy, radius) {
        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, Math.PI * 2);
        ctx.stroke();
    }

    function roundedRect(ctx, x, y, widthValue, heightValue, radius) {
        ctx.beginPath();
        ctx.moveTo(x + radius, y);
        ctx.lineTo(x + widthValue - radius, y);
        ctx.quadraticCurveTo(x + widthValue, y, x + widthValue, y + radius);
        ctx.lineTo(x + widthValue, y + heightValue - radius);
        ctx.quadraticCurveTo(x + widthValue, y + heightValue, x + widthValue - radius, y + heightValue);
        ctx.lineTo(x + radius, y + heightValue);
        ctx.quadraticCurveTo(x, y + heightValue, x, y + heightValue - radius);
        ctx.lineTo(x, y + radius);
        ctx.quadraticCurveTo(x, y, x + radius, y);
        ctx.stroke();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.clearRect(0, 0, width, height);
        ctx.strokeStyle = lineColor;
        ctx.fillStyle = lineColor;
        ctx.lineWidth = strokeWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        const w = width;
        const h = height;
        const x = w / 2;
        const y = h / 2;

        if (kind === "home") {
            line(ctx, [[w * .12, h * .48], [x, h * .16], [w * .88, h * .48]]);
            line(ctx, [[w * .22, h * .43], [w * .22, h * .84], [w * .42, h * .84], [w * .42, h * .62], [w * .61, h * .62], [w * .61, h * .84], [w * .78, h * .84], [w * .78, h * .43]]);
        } else if (kind === "lightNav") {
            circle(ctx, x, y, w * .15);
            for (let index = 0; index < 8; ++index) {
                const angle = index * Math.PI / 4;
                line(ctx, [[x + Math.cos(angle) * w * .26, y + Math.sin(angle) * h * .26], [x + Math.cos(angle) * w * .42, y + Math.sin(angle) * h * .42]]);
            }
        } else if (kind === "climate") {
            circle(ctx, w * .42, h * .71, w * .15);
            roundedRect(ctx, w * .35, h * .13, w * .14, h * .57, w * .07);
            line(ctx, [[w * .42, h * .31], [w * .42, h * .68]]);
            circle(ctx, w * .73, h * .30, w * .08);
            for (let index = 0; index < 8; ++index) {
                const angle = index * Math.PI / 4;
                line(ctx, [[w * .73 + Math.cos(angle) * w * .13, h * .30 + Math.sin(angle) * h * .13], [w * .73 + Math.cos(angle) * w * .18, h * .30 + Math.sin(angle) * h * .18]]);
            }
        } else if (kind === "energy") {
            roundedRect(ctx, w * .14, h * .25, w * .65, h * .51, w * .07);
            roundedRect(ctx, w * .79, h * .39, w * .08, h * .23, w * .02);
            line(ctx, [[w * .52, h * .31], [w * .37, h * .55], [w * .49, h * .55], [w * .43, h * .72], [w * .67, h * .44], [w * .54, h * .44]]);
        } else if (kind === "water") {
            ctx.beginPath();
            ctx.moveTo(x, h * .10);
            ctx.bezierCurveTo(w * .76, h * .43, w * .78, h * .67, x, h * .86);
            ctx.bezierCurveTo(w * .22, h * .67, w * .24, h * .43, x, h * .10);
            ctx.stroke();
        } else if (kind === "system" || kind === "sliders") {
            line(ctx, [[w * .16, h * .25], [w * .84, h * .25]]);
            line(ctx, [[w * .16, h * .50], [w * .84, h * .50]]);
            line(ctx, [[w * .16, h * .75], [w * .84, h * .75]]);
            circle(ctx, w * .35, h * .25, w * .075);
            circle(ctx, w * .66, h * .50, w * .075);
            circle(ctx, w * .43, h * .75, w * .075);
        } else if (kind === "theme") {
            ctx.beginPath();
            ctx.arc(x, y, w * .31, -.45 * Math.PI, 1.55 * Math.PI);
            ctx.bezierCurveTo(w * .43, h * .74, w * .48, h * .58, w * .55, h * .45);
            ctx.bezierCurveTo(w * .65, h * .27, w * .53, h * .18, x, h * .19);
            ctx.stroke();
        } else if (kind === "cabinLight") {
            ctx.beginPath();
            ctx.moveTo(w * .20, h * .45);
            ctx.quadraticCurveTo(x, h * .28, w * .80, h * .45);
            ctx.lineTo(w * .72, h * .69);
            ctx.quadraticCurveTo(x, h * .79, w * .28, h * .69);
            ctx.closePath();
            ctx.stroke();
            line(ctx, [[w * .34, h * .56], [w * .66, h * .56]]);
            line(ctx, [[w * .22, h * .81], [w * .78, h * .81]]);
            line(ctx, [[x, h * .08], [x, h * .18]]);
        } else if (kind === "workLightLeft" || kind === "workLightRight") {
            const left = kind === "workLightLeft";
            roundedRect(ctx, left ? w * .28 : w * .10, h * .25, w * .60, h * .42, w * .06);
            for (let index = 0; index < 3; ++index)
                circle(ctx, (left ? w * .41 : w * .23) + index * w * .17, h * .46, w * .03);
            const edge = left ? w * .22 : w * .76;
            const ray = left ? w * .04 : w * .94;
            line(ctx, [[edge, h * .31], [ray, h * .20]]);
            line(ctx, [[edge, h * .46], [ray, h * .46]]);
            line(ctx, [[edge, h * .61], [ray, h * .72]]);
        } else if (kind === "rearLight") {
            roundedRect(ctx, w * .34, h * .22, w * .50, h * .50, w * .09);
            circle(ctx, w * .49, h * .39, w * .03);
            circle(ctx, w * .68, h * .39, w * .03);
            circle(ctx, w * .49, h * .57, w * .03);
            circle(ctx, w * .68, h * .57, w * .03);
            line(ctx, [[w * .25, h * .28], [w * .08, h * .17]]);
            line(ctx, [[w * .25, h * .47], [w * .05, h * .47]]);
            line(ctx, [[w * .25, h * .65], [w * .08, h * .76]]);
        } else if (kind === "lightBar" || kind === "warningBar") {
            roundedRect(ctx, w * .06, h * .34, w * .88, h * .32, w * .06);
            for (let index = 0; index < 5; ++index) {
                const px = w * (.18 + index * .16);
                if (kind === "lightBar")
                    circle(ctx, px, y, w * .025);
                else
                    line(ctx, [[px - w * .035, h * .42], [px + w * .035, h * .58]]);
            }
            if (kind === "warningBar") {
                line(ctx, [[x, h * .24], [x, h * .09]]);
                line(ctx, [[w * .16, h * .26], [w * .06, h * .16]]);
                line(ctx, [[w * .84, h * .26], [w * .94, h * .16]]);
            }
        } else if (kind === "highBeam") {
            ctx.beginPath();
            ctx.moveTo(w * .53, h * .22);
            ctx.bezierCurveTo(w * .72, h * .22, w * .84, h * .34, w * .84, y);
            ctx.bezierCurveTo(w * .84, h * .66, w * .72, h * .78, w * .53, h * .78);
            ctx.closePath();
            ctx.stroke();
            line(ctx, [[w * .41, h * .28], [w * .08, h * .28]]);
            line(ctx, [[w * .41, h * .43], [w * .08, h * .43]]);
            line(ctx, [[w * .41, h * .58], [w * .08, h * .58]]);
            line(ctx, [[w * .41, h * .73], [w * .08, h * .73]]);
        } else if (kind === "outlet") {
            roundedRect(ctx, w * .17, h * .14, w * .66, h * .68, w * .12);
            line(ctx, [[w * .38, h * .34], [w * .38, h * .51]]);
            line(ctx, [[w * .62, h * .34], [w * .62, h * .51]]);
            ctx.beginPath();
            ctx.moveTo(w * .35, h * .67);
            ctx.quadraticCurveTo(x, h * .54, w * .65, h * .67);
            ctx.stroke();
        } else if (kind === "pump") {
            circle(ctx, w * .40, h * .55, w * .21);
            circle(ctx, w * .40, h * .55, w * .055);
            line(ctx, [[w * .07, h * .55], [w * .19, h * .55]]);
            line(ctx, [[w * .61, h * .55], [w * .86, h * .55], [w * .86, h * .76]]);
            ctx.beginPath();
            ctx.moveTo(w * .74, h * .12);
            ctx.bezierCurveTo(w * .85, h * .28, w * .85, h * .40, w * .74, h * .46);
            ctx.bezierCurveTo(w * .63, h * .40, w * .63, h * .28, w * .74, h * .12);
            ctx.stroke();
        } else if (kind === "satellite") {
            ctx.beginPath();
            ctx.moveTo(w * .17, h * .20);
            ctx.quadraticCurveTo(w * .25, h * .65, w * .70, h * .72);
            ctx.stroke();
            line(ctx, [[w * .45, h * .57], [w * .30, h * .88]]);
            line(ctx, [[w * .14, h * .88], [w * .48, h * .88]]);
            line(ctx, [[w * .40, h * .42], [w * .67, h * .14]]);
            ctx.beginPath();
            ctx.arc(w * .70, h * .16, w * .15, -.8, 1.55);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w * .70, h * .16, w * .29, -.8, 1.55);
            ctx.stroke();
        } else if (kind === "fan") {
            circle(ctx, x, y, w * .07);
            for (let index = 0; index < 3; ++index) {
                const angle = index * Math.PI * 2 / 3;
                ctx.beginPath();
                ctx.moveTo(x + Math.cos(angle) * w * .10, y + Math.sin(angle) * h * .10);
                ctx.quadraticCurveTo(x + Math.cos(angle + .35) * w * .45, y + Math.sin(angle + .35) * h * .45, x + Math.cos(angle + 1.25) * w * .15, y + Math.sin(angle + 1.25) * h * .15);
                ctx.stroke();
            }
        } else if (kind === "plug") {
            line(ctx, [[w * .34, h * .10], [w * .34, h * .31]]);
            line(ctx, [[w * .66, h * .10], [w * .66, h * .31]]);
            ctx.beginPath();
            ctx.moveTo(w * .25, h * .31);
            ctx.lineTo(w * .75, h * .31);
            ctx.lineTo(w * .75, h * .50);
            ctx.bezierCurveTo(w * .75, h * .68, w * .63, h * .77, x, h * .77);
            ctx.bezierCurveTo(w * .37, h * .77, w * .25, h * .68, w * .25, h * .50);
            ctx.closePath();
            ctx.stroke();
            line(ctx, [[x, h * .77], [x, h * .92]]);
        } else if (kind === "solar") {
            circle(ctx, w * .27, h * .27, w * .10);
            for (let index = 0; index < 8; ++index) {
                const angle = index * Math.PI / 4;
                line(ctx, [[w * .27 + Math.cos(angle) * w * .15, h * .27 + Math.sin(angle) * h * .15], [w * .27 + Math.cos(angle) * w * .20, h * .27 + Math.sin(angle) * h * .20]]);
            }
            ctx.beginPath();
            ctx.moveTo(w * .29, h * .52);
            ctx.lineTo(w * .79, h * .52);
            ctx.lineTo(w * .88, h * .86);
            ctx.lineTo(w * .20, h * .86);
            ctx.closePath();
            ctx.stroke();
            line(ctx, [[w * .25, h * .69], [w * .84, h * .69]]);
            line(ctx, [[w * .38, h * .52], [w * .35, h * .86]]);
            line(ctx, [[w * .65, h * .52], [w * .69, h * .86]]);
        } else if (kind === "alternator") {
            ctx.beginPath();
            ctx.arc(x, y, w * .31, -.55, Math.PI * 1.60);
            ctx.stroke();
            line(ctx, [[w * .77, h * .30], [w * .77, h * .12]]);
            line(ctx, [[w * .77, h * .30], [w * .59, h * .30]]);
            line(ctx, [[w * .23, h * .70], [w * .23, h * .88]]);
            line(ctx, [[w * .23, h * .70], [w * .41, h * .70]]);
            line(ctx, [[w * .55, h * .25], [w * .38, h * .55], [w * .50, h * .55], [w * .45, h * .77], [w * .65, h * .46], [w * .54, h * .46]]);
        } else if (kind === "battery") {
            roundedRect(ctx, w * .12, h * .25, w * .68, h * .50, w * .09);
            roundedRect(ctx, w * .80, h * .40, w * .08, h * .20, w * .02);
            line(ctx, [[w * .30, h * .39], [w * .30, h * .61]]);
            line(ctx, [[w * .22, h * .50], [w * .38, h * .50]]);
            line(ctx, [[w * .61, h * .36], [w * .48, h * .55], [w * .59, h * .55], [w * .53, h * .68], [w * .70, h * .45], [w * .60, h * .45]]);
        } else if (kind === "flame") {
            ctx.beginPath();
            ctx.moveTo(x, h * .10);
            ctx.bezierCurveTo(w * .72, h * .35, w * .75, h * .62, x, h * .88);
            ctx.bezierCurveTo(w * .26, h * .69, w * .25, h * .43, w * .39, h * .28);
            ctx.bezierCurveTo(w * .40, h * .47, w * .55, h * .47, x, h * .10);
            ctx.stroke();
        } else if (kind === "back") {
            line(ctx, [[w * .70, h * .20], [w * .35, y], [w * .70, h * .80]]);
            line(ctx, [[w * .35, y], [w * .90, y]]);
        } else if (kind === "clock") {
            circle(ctx, x, y, w * .34);
            line(ctx, [[x, h * .30], [x, y], [w * .67, h * .61]]);
        } else if (kind === "check") {
            line(ctx, [[w * .17, h * .52], [w * .40, h * .75], [w * .84, h * .25]]);
        } else if (kind === "external") {
            roundedRect(ctx, w * .13, h * .25, w * .56, h * .61, w * .07);
            line(ctx, [[w * .48, h * .14], [w * .86, h * .14], [w * .86, h * .52]]);
            line(ctx, [[w * .86, h * .14], [w * .42, h * .58]]);
        } else {
            circle(ctx, x, y, w * .32);
        }
    }
}
