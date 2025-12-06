package output

import (
	"encoding/csv"
	"io"
)

// CSVFormatter CSV 格式化器
type CSVFormatter struct {
	writer  io.Writer
	headers []string
	rows    [][]string
}

// NewCSVFormatter 创建 CSV 格式化器
func NewCSVFormatter(writer io.Writer) *CSVFormatter {
	return &CSVFormatter{
		writer: writer,
		rows:   make([][]string, 0),
	}
}

// SetHeader 设置表头
func (f *CSVFormatter) SetHeader(headers []string) {
	f.headers = headers
}

// AddRow 添加行
func (f *CSVFormatter) AddRow(row []string) {
	f.rows = append(f.rows, row)
}

// AddRows 批量添加行
func (f *CSVFormatter) AddRows(rows [][]string) {
	f.rows = append(f.rows, rows...)
}

// Render 渲染输出
func (f *CSVFormatter) Render() error {
	w := csv.NewWriter(f.writer)

	// 写入表头
	if len(f.headers) > 0 {
		if err := w.Write(f.headers); err != nil {
			return err
		}
	}

	// 写入数据行
	for _, row := range f.rows {
		if err := w.Write(row); err != nil {
			return err
		}
	}

	w.Flush()
	return w.Error()
}

// RenderMap 渲染键值对
func (f *CSVFormatter) RenderMap(data map[string]string, title string) error {
	w := csv.NewWriter(f.writer)

	// 写入表头
	if err := w.Write([]string{"Key", "Value"}); err != nil {
		return err
	}

	// 写入数据
	for key, value := range data {
		if err := w.Write([]string{key, value}); err != nil {
			return err
		}
	}

	w.Flush()
	return w.Error()
}
