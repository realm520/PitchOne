package output

import (
	"fmt"
	"io"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// PitchOne 品牌色
var (
	colorPrimary    = lipgloss.Color("#00D4AA")
	colorAccent     = lipgloss.Color("#7C3AED")
	colorSuccess    = lipgloss.Color("#10B981")
	colorWarning    = lipgloss.Color("#F59E0B")
	colorError      = lipgloss.Color("#EF4444")
	colorInfo       = lipgloss.Color("#3B82F6")
	colorText       = lipgloss.Color("#E5E7EB")
	colorTextMuted  = lipgloss.Color("#9CA3AF")
	colorBorder     = lipgloss.Color("#374151")
	colorTableHeader = lipgloss.Color("#6366F1")
)

// 预定义样式
var (
	titleStyle = lipgloss.NewStyle().
			Foreground(colorPrimary).
			Bold(true)

	dividerStyle = lipgloss.NewStyle().
			Foreground(colorBorder)

	headerStyle = lipgloss.NewStyle().
			Foreground(colorTableHeader).
			Bold(true)

	cellStyle = lipgloss.NewStyle().
			Foreground(colorText)

	keyStyle = lipgloss.NewStyle().
			Foreground(colorTextMuted)

	valueStyle = lipgloss.NewStyle().
			Foreground(colorText)

	successStyle = lipgloss.NewStyle().
			Foreground(colorSuccess).
			Bold(true)

	warningStyle = lipgloss.NewStyle().
			Foreground(colorWarning).
			Bold(true)

	errorStyle = lipgloss.NewStyle().
			Foreground(colorError).
			Bold(true)

	infoStyle = lipgloss.NewStyle().
			Foreground(colorInfo)

	addressStyle = lipgloss.NewStyle().
			Foreground(colorAccent)

	amountStyle = lipgloss.NewStyle().
			Foreground(colorSuccess)

	percentStyle = lipgloss.NewStyle().
			Foreground(colorInfo)
)

// TableFormatter 表格格式化器
type TableFormatter struct {
	writer  io.Writer
	headers []string
	rows    [][]string
	widths  []int
}

// NewTableFormatter 创建表格格式化器
func NewTableFormatter(writer io.Writer) *TableFormatter {
	return &TableFormatter{
		writer: writer,
		rows:   make([][]string, 0),
	}
}

// SetHeader 设置表头
func (f *TableFormatter) SetHeader(headers []string) {
	f.headers = headers
	f.widths = make([]int, len(headers))
	for i, h := range headers {
		f.widths[i] = len(h)
	}
}

// AddRow 添加行
func (f *TableFormatter) AddRow(row []string) {
	f.rows = append(f.rows, row)
	for i, cell := range row {
		if i < len(f.widths) {
			// 计算实际显示宽度（去除 ANSI 转义序列）
			plainLen := len(stripAnsi(cell))
			if plainLen > f.widths[i] {
				f.widths[i] = plainLen
			}
		}
	}
}

// AddRows 批量添加行
func (f *TableFormatter) AddRows(rows [][]string) {
	for _, row := range rows {
		f.AddRow(row)
	}
}

// Render 渲染输出
func (f *TableFormatter) Render() error {
	if len(f.headers) == 0 {
		return nil
	}

	// 渲染上边框
	fmt.Fprintln(f.writer, f.renderTopBorder())

	// 渲染表头
	fmt.Fprintln(f.writer, f.renderHeaderRow())

	// 渲染表头分隔线
	fmt.Fprintln(f.writer, f.renderHeaderSeparator())

	// 渲染数据行
	for _, row := range f.rows {
		fmt.Fprintln(f.writer, f.renderDataRow(row))
	}

	// 渲染下边框
	fmt.Fprintln(f.writer, f.renderBottomBorder())

	return nil
}

func (f *TableFormatter) renderTopBorder() string {
	var parts []string
	for i, w := range f.widths {
		if i == 0 {
			parts = append(parts, "╭"+strings.Repeat("─", w+2))
		} else {
			parts = append(parts, "┬"+strings.Repeat("─", w+2))
		}
	}
	return dividerStyle.Render(strings.Join(parts, "") + "╮")
}

func (f *TableFormatter) renderBottomBorder() string {
	var parts []string
	for i, w := range f.widths {
		if i == 0 {
			parts = append(parts, "╰"+strings.Repeat("─", w+2))
		} else {
			parts = append(parts, "┴"+strings.Repeat("─", w+2))
		}
	}
	return dividerStyle.Render(strings.Join(parts, "") + "╯")
}

func (f *TableFormatter) renderHeaderSeparator() string {
	var parts []string
	for i, w := range f.widths {
		if i == 0 {
			parts = append(parts, "├"+strings.Repeat("─", w+2))
		} else {
			parts = append(parts, "┼"+strings.Repeat("─", w+2))
		}
	}
	return dividerStyle.Render(strings.Join(parts, "") + "┤")
}

func (f *TableFormatter) renderHeaderRow() string {
	var cells []string
	for i, h := range f.headers {
		cell := headerStyle.Render(padRight(h, f.widths[i]))
		cells = append(cells, cell)
	}
	border := dividerStyle.Render("│")
	return border + " " + strings.Join(cells, " "+border+" ") + " " + border
}

func (f *TableFormatter) renderDataRow(row []string) string {
	var cells []string
	for i, cell := range row {
		width := 10
		if i < len(f.widths) {
			width = f.widths[i]
		}
		styledCell := f.styleCell(cell, width)
		cells = append(cells, styledCell)
	}
	border := dividerStyle.Render("│")
	return border + " " + strings.Join(cells, " "+border+" ") + " " + border
}

func (f *TableFormatter) styleCell(cell string, width int) string {
	// 根据内容类型应用样式
	paddedCell := padRight(cell, width)

	switch cell {
	case "Open":
		return successStyle.Render(paddedCell)
	case "Locked":
		return warningStyle.Render(paddedCell)
	case "Resolved":
		return infoStyle.Render(paddedCell)
	case "Finalized":
		return lipgloss.NewStyle().Foreground(colorTextMuted).Render(paddedCell)
	case "Cancelled":
		return errorStyle.Render(paddedCell)
	case "Yes", "Active":
		return successStyle.Render(paddedCell)
	case "No", "Inactive":
		return errorStyle.Render(paddedCell)
	}

	// 检测地址（0x开头）
	if strings.HasPrefix(cell, "0x") {
		return addressStyle.Render(paddedCell)
	}

	// 检测金额
	if strings.Contains(cell, "USDC") || strings.Contains(cell, "pLP") {
		return amountStyle.Render(paddedCell)
	}

	// 检测百分比
	if strings.HasSuffix(cell, "%") || strings.Contains(cell, "bps") {
		return percentStyle.Render(paddedCell)
	}

	return cellStyle.Render(paddedCell)
}

// RenderMap 渲染键值对
func (f *TableFormatter) RenderMap(data map[string]string, title string) error {
	if title != "" {
		fmt.Fprintln(f.writer, titleStyle.Render(title))
		fmt.Fprintln(f.writer, dividerStyle.Render(strings.Repeat("─", len(title)+4)))
		fmt.Fprintln(f.writer)
	}

	// 计算最大键宽度
	maxKeyWidth := 0
	for key := range data {
		if len(key) > maxKeyWidth {
			maxKeyWidth = len(key)
		}
	}

	// 渲染键值对
	styledKeyStyle := keyStyle.Width(maxKeyWidth + 2)
	for key, value := range data {
		styledValue := styleValue(value)
		fmt.Fprintf(f.writer, "%s%s\n", styledKeyStyle.Render(key), styledValue)
	}

	return nil
}

// RenderOrderedMap 渲染有序键值对
func (f *TableFormatter) RenderOrderedMap(keys []string, data map[string]string, title string) error {
	if title != "" {
		fmt.Fprintln(f.writer, titleStyle.Render(title))
		fmt.Fprintln(f.writer, dividerStyle.Render(strings.Repeat("─", len(title)+4)))
		fmt.Fprintln(f.writer)
	}

	// 计算最大键宽度
	maxKeyWidth := 0
	for _, key := range keys {
		if len(key) > maxKeyWidth {
			maxKeyWidth = len(key)
		}
	}

	// 渲染键值对
	styledKeyStyle := keyStyle.Width(maxKeyWidth + 2)
	for _, key := range keys {
		value := data[key]
		styledValue := styleValue(value)
		fmt.Fprintf(f.writer, "%s%s\n", styledKeyStyle.Render(key), styledValue)
	}

	return nil
}

// RenderBoxed 渲染带边框的表格
func (f *TableFormatter) RenderBoxed(title string) error {
	return f.Render()
}

func styleValue(value string) string {
	// 检测地址
	if strings.HasPrefix(value, "0x") {
		return addressStyle.Render(value)
	}

	// 检测金额
	if strings.Contains(value, "USDC") || strings.Contains(value, "pLP") {
		return amountStyle.Render(value)
	}

	// 检测百分比
	if strings.HasSuffix(value, "%") {
		return percentStyle.Render(value)
	}

	// 检测状态
	switch value {
	case "Open", "Yes", "Active":
		return successStyle.Render(value)
	case "Locked":
		return warningStyle.Render(value)
	case "Cancelled", "No", "Inactive":
		return errorStyle.Render(value)
	}

	return valueStyle.Render(value)
}

// padRight 右填充字符串
func padRight(s string, width int) string {
	plainLen := len(stripAnsi(s))
	if plainLen >= width {
		return s
	}
	return s + strings.Repeat(" ", width-plainLen)
}

// stripAnsi 移除 ANSI 转义序列（用于计算实际显示宽度）
func stripAnsi(s string) string {
	// 简单实现，移除常见 ANSI 序列
	result := s
	for strings.Contains(result, "\x1b[") {
		start := strings.Index(result, "\x1b[")
		end := start + 2
		for end < len(result) && result[end] != 'm' {
			end++
		}
		if end < len(result) {
			result = result[:start] + result[end+1:]
		} else {
			break
		}
	}
	return result
}
