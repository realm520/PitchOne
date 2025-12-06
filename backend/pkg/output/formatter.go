package output

import (
	"io"
	"os"
)

// Format 输出格式
type Format string

const (
	FormatTable Format = "table"
	FormatJSON  Format = "json"
	FormatCSV   Format = "csv"
)

// Formatter 输出格式化器接口
type Formatter interface {
	// SetHeader 设置表头
	SetHeader(headers []string)
	// AddRow 添加行
	AddRow(row []string)
	// AddRows 批量添加行
	AddRows(rows [][]string)
	// Render 渲染输出
	Render() error
	// RenderMap 渲染键值对
	RenderMap(data map[string]string, title string) error
}

// New 创建格式化器
func New(format Format, writer io.Writer) Formatter {
	if writer == nil {
		writer = os.Stdout
	}

	switch format {
	case FormatJSON:
		return NewJSONFormatter(writer)
	case FormatCSV:
		return NewCSVFormatter(writer)
	default:
		return NewTableFormatter(writer)
	}
}

// NewFromString 从字符串创建格式化器
func NewFromString(format string) Formatter {
	return New(Format(format), os.Stdout)
}

// Print 快速打印表格
func Print(format string, headers []string, rows [][]string) error {
	f := NewFromString(format)
	f.SetHeader(headers)
	f.AddRows(rows)
	return f.Render()
}

// PrintMap 快速打印键值对
func PrintMap(format string, data map[string]string, title string) error {
	f := NewFromString(format)
	return f.RenderMap(data, title)
}
