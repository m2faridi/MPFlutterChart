import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:mp_flutter_chart/chart/mp/core/axis/y_axis.dart';
import 'package:mp_flutter_chart/chart/mp/core/enums/axis_dependency.dart';
import 'package:mp_flutter_chart/chart/mp/core/enums/limite_label_postion.dart';
import 'package:mp_flutter_chart/chart/mp/core/enums/y_axis_label_position.dart';
import 'package:mp_flutter_chart/chart/mp/core/limit_line.dart';
import 'package:mp_flutter_chart/chart/mp/core/render/y_axis_renderer.dart';
import 'package:mp_flutter_chart/chart/mp/core/transformer/transformer.dart';
import 'package:mp_flutter_chart/chart/mp/core/utils/painter_utils.dart';
import 'package:mp_flutter_chart/chart/mp/core/view_port.dart';
import 'package:mp_flutter_chart/chart/mp/core/poolable/point.dart';
import 'package:mp_flutter_chart/chart/mp/core/utils/utils.dart';

class YAxisRendererHorizontalBarChart extends YAxisRenderer {
  YAxisRendererHorizontalBarChart(
      ViewPortHandler viewPortHandler, YAxis yAxis, Transformer trans)
      : super(viewPortHandler, yAxis, trans);

  /// Computes the axis values.
  ///
  /// @param yMin - the minimum y-value in the data object for this axis
  /// @param yMax - the maximum y-value in the data object for this axis
  @override
  void computeAxis(double yMin, double yMax, bool inverted) {
    // calculate the starting and entry point of the y-labels (depending on
    // zoom / contentrect bounds)
    if (viewPortHandler.contentHeight() > 10 &&
        !viewPortHandler.isFullyZoomedOutX()) {
      MPPointD p1 = trans.getValuesByTouchPoint1(
          viewPortHandler.contentLeft(), viewPortHandler.contentTop());
      MPPointD p2 = trans.getValuesByTouchPoint1(
          viewPortHandler.contentRight(), viewPortHandler.contentTop());

      if (!inverted) {
        yMin = p1.x;
        yMax = p2.x;
      } else {
        yMin = p2.x;
        yMax = p1.x;
      }

      MPPointD.recycleInstance2(p1);
      MPPointD.recycleInstance2(p2);
    }

    computeAxisValues(yMin, yMax);
  }

  /// draws the y-axis labels to the screen
  @override
  void renderAxisLabels(Canvas c) {
    if (!yAxis.enabled || !yAxis.drawLabels) return;

    List<double> positions = getTransformedPositions();

    axisLabelPaint = PainterUtils.create(
        axisLabelPaint, null, yAxis.textColor, yAxis.textSize);

//    double baseYOffset = Utils.convertDpToPixel(2.5);
//    double textHeight = Utils.calcTextHeight(axisLabelPaint, "Q").toDouble();

    AxisDependency dependency = yAxis.axisDependency;
    YAxisLabelPosition labelPosition = yAxis.position;

    double yPos = 0;

    if (dependency == AxisDependency.LEFT) {
      if (labelPosition == YAxisLabelPosition.OUTSIDE_CHART) {
        yPos = viewPortHandler.contentTop();
      } else {
        yPos = viewPortHandler.contentTop();
      }
    } else {
      if (labelPosition == YAxisLabelPosition.OUTSIDE_CHART) {
        yPos = viewPortHandler.contentBottom();
      } else {
        yPos = viewPortHandler.contentBottom();
      }
    }

    drawYLabels(c, yPos, positions, dependency, labelPosition);
  }

  @override
  void renderAxisLine(Canvas c) {
    if (!yAxis.enabled || !yAxis.drawAxisLine) return;
    axisLinePaint = Paint()
      ..color = yAxis.axisLineColor
      ..strokeWidth = yAxis.axisLineWidth;

    if (yAxis.axisDependency == AxisDependency.LEFT) {
      c.drawLine(
          Offset(viewPortHandler.contentLeft(), viewPortHandler.contentTop()),
          Offset(viewPortHandler.contentRight(), viewPortHandler.contentTop()),
          axisLinePaint);
    } else {
      c.drawLine(
          Offset(
              viewPortHandler.contentLeft(), viewPortHandler.contentBottom()),
          Offset(
              viewPortHandler.contentRight(), viewPortHandler.contentBottom()),
          axisLinePaint);
    }
  }

  /// draws the y-labels on the specified x-position
  ///
  /// @param fixedPosition
  /// @param positions
  @override
  void drawYLabels(Canvas c, double fixedPosition, List<double> positions,
      AxisDependency axisDependency, YAxisLabelPosition position) {
    axisLabelPaint = PainterUtils.create(
        axisLabelPaint, null, yAxis.textColor, yAxis.textSize);

    final int from = yAxis.drawBottomYLabelEntry ? 0 : 1;
    final int to =
        yAxis.drawTopYLabelEntry ? yAxis.entryCount : (yAxis.entryCount - 1);

    for (int i = from; i < to; i++) {
      String text = yAxis.getFormattedLabel(i);
      axisLabelPaint.text =
          TextSpan(text: text, style: axisLabelPaint.text.style);
      axisLabelPaint.layout();

      if (axisDependency == AxisDependency.LEFT) {
        if (position == YAxisLabelPosition.OUTSIDE_CHART) {
          axisLabelPaint.paint(
              c,
              Offset(positions[i * 2] - axisLabelPaint.width / 2,
                  fixedPosition - axisLabelPaint.height));
        } else {
          axisLabelPaint.paint(
              c,
              Offset(
                  positions[i * 2] - axisLabelPaint.width / 2, fixedPosition));
        }
      } else {
        if (position == YAxisLabelPosition.OUTSIDE_CHART) {
          axisLabelPaint.paint(
              c,
              Offset(
                  positions[i * 2] - axisLabelPaint.width / 2, fixedPosition));
        } else {
          axisLabelPaint.paint(
              c,
              Offset(positions[i * 2] - axisLabelPaint.width / 2,
                  fixedPosition - axisLabelPaint.height));
        }
      }
    }
  }

  @override
  List<double> getTransformedPositions() {
    if (mGetTransformedPositionsBuffer.length != yAxis.entryCount * 2) {
      mGetTransformedPositionsBuffer = List(yAxis.entryCount * 2);
    }
    List<double> positions = mGetTransformedPositionsBuffer;

    for (int i = 0; i < positions.length; i += 2) {
      // only fill x values, y values are not needed for x-labels
      positions[i] = yAxis.entries[i ~/ 2];
    }

    trans.pointValuesToPixel(positions);
    return positions;
  }

  @override
  Rect getGridClippingRect() {
    mGridClippingRect = Rect.fromLTRB(
        viewPortHandler.getContentRect().left - axis.gridLineWidth,
        viewPortHandler.getContentRect().top - axis.gridLineWidth,
        viewPortHandler.getContentRect().right,
        viewPortHandler.getContentRect().bottom);
    return mGridClippingRect;
  }

  @override
  Path linePath(Path p, int i, List<double> positions) {
    p.moveTo(positions[i], viewPortHandler.contentTop());
    p.lineTo(positions[i], viewPortHandler.contentBottom());
    return p;
  }

  Path mDrawZeroLinePathBuffer = Path();

  @override
  void drawZeroLine(Canvas c) {
    c.save();
    mZeroLineClippingRect = Rect.fromLTRB(
        viewPortHandler.getContentRect().left - yAxis.zeroLineWidth,
        viewPortHandler.getContentRect().top - yAxis.zeroLineWidth,
        viewPortHandler.getContentRect().right,
        viewPortHandler.getContentRect().bottom);
    c.clipRect(limitLineClippingRect);

    // draw zero line
    MPPointD pos = trans.getPixelForValues(0, 0);

    zeroLinePaint
      ..color = yAxis.zeroLineColor
      ..strokeWidth = yAxis.zeroLineWidth;

    Path zeroLinePath = mDrawZeroLinePathBuffer;
    zeroLinePath.reset();

    zeroLinePath.moveTo(pos.x - 1, viewPortHandler.contentTop());
    zeroLinePath.lineTo(pos.x - 1, viewPortHandler.contentBottom());

    // draw a path because lines don't support dashing on lower android versions
    c.drawPath(zeroLinePath, zeroLinePaint);

    c.restore();
  }

  Path mRenderLimitLinesPathBuffer = Path();
  List<double> mRenderLimitLinesBuffer = List(4);

  /// Draws the LimitLines associated with this axis to the screen.
  /// This is the standard XAxis renderer using the YAxis limit lines.
  ///
  /// @param c
  @override
  void renderLimitLines(Canvas c) {
    List<LimitLine> limitLines = yAxis.getLimitLines();

    if (limitLines == null || limitLines.length <= 0) return;

    List<double> pts = mRenderLimitLinesBuffer;
    pts[0] = 0;
    pts[1] = 0;
    pts[2] = 0;
    pts[3] = 0;
    Path limitLinePath = mRenderLimitLinesPathBuffer;
    limitLinePath.reset();

    for (int i = 0; i < limitLines.length; i++) {
      LimitLine l = limitLines[i];

      if (!l.enabled) continue;

      c.save();
      limitLineClippingRect = Rect.fromLTRB(
          viewPortHandler.getContentRect().left - l.lineWidth,
          viewPortHandler.getContentRect().top - l.lineWidth,
          viewPortHandler.getContentRect().right,
          viewPortHandler.getContentRect().bottom);
      c.clipRect(limitLineClippingRect);

      pts[0] = l.limit;
      pts[2] = l.limit;

      trans.pointValuesToPixel(pts);

      pts[1] = viewPortHandler.contentTop();
      pts[3] = viewPortHandler.contentBottom();

      limitLinePath.moveTo(pts[0], pts[1]);
      limitLinePath.lineTo(pts[2], pts[3]);

      limitLinePaint
        ..style = PaintingStyle.stroke
        ..color = l.lineColor
        ..strokeWidth = l.lineWidth;

      if (l.dashPathEffect != null) {
        limitLinePath = l.dashPathEffect.convert2DashPath(limitLinePath);
      }
      c.drawPath(limitLinePath, limitLinePaint);
      limitLinePath.reset();

      String label = l.label;

      // if drawing the limit-value label is enabled
      if (label != null && label.isNotEmpty) {
        axisLabelPaint =
            PainterUtils.create(axisLabelPaint, label, l.textColor, l.textSize);
        axisLabelPaint.layout();

        final LimitLabelPosition position = l.labelPosition;

        if (position == LimitLabelPosition.RIGHT_TOP) {
          final double labelLineHeight =
              Utils.calcTextHeight(axisLabelPaint, label).toDouble();
          axisLabelPaint.paint(c,
              Offset(pts[0], viewPortHandler.contentTop() + labelLineHeight));
        } else if (position == LimitLabelPosition.RIGHT_BOTTOM) {
          axisLabelPaint.paint(
              c, Offset(pts[0], viewPortHandler.contentBottom()));
        } else if (position == LimitLabelPosition.LEFT_TOP) {
          final double labelLineHeight =
              Utils.calcTextHeight(axisLabelPaint, label).toDouble();
          axisLabelPaint.paint(c,
              Offset(pts[0], viewPortHandler.contentTop() + labelLineHeight));
        } else {
          axisLabelPaint.paint(
              c, Offset(pts[0], viewPortHandler.contentBottom()));
        }
      }

      c.restore();
    }
  }
}
