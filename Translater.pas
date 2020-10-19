{$reference 'System.Windows.Forms.dll'}
{$reference 'System.Drawing.dll'}
uses System,System.Drawing,System.Windows.Forms, System.IO;
var f: Form:= new Form();  
    t2:= new TextBox();
    t1:= new TextBox();
    native_Swap:= new Button();
    native_translate:= new Button();
    native_Clear:= new Button();
    native_copy:= new Button();
    native_paste:= new Button();
    native_Russian:= new &Label();
    native_English:= new &Label();
    
const PATH_TRANSLATE = 'C:\Users\fdshfgas\Documents\_USB_\Разработки 2020\App 2020\TRANSLATER\translate.txt';
var // Переменные определения какой язык используется в текущий момент
    isRu: boolean:= false;
    isEn: boolean:= true; 
    // Были ли языки поменяны местами
    isSwapped: boolean:= false;
/// Базовые функции для работы переводчика
type TranslaterApiBase = class
    private static procedure ClearEx(textbox_: TextBox:= nil);
       begin
         if (textbox_ = nil)then begin
             t1.Clear();
             t2.Clear();
         end else begin
             textbox_.Clear();
         end;
       end;
    /// Меняет местами содержимое полей при смене направления перевода
    private static procedure Swap(textBox1, texBox2: TextBox);
       begin
         var tmp:= textBox1.Text;
         textBox1.Text:= texBox2.Text;
         texBox2.Text:= tmp;
       end;
    /// Очищает все поля
    public static procedure Clear(sender: object; args: EventArgs);
        begin
           ClearEx();
        end;
    ///Является ли поле пустым
    public static function IsEmpty(textBox_ : TextBox):= (textBox_.Text = '')? true: false;
    ///Проверяет содержит ли строка русские буквы
    public static function IsRussian(str: string): boolean;
     begin
       var chars:= str.ToCharArray();
       for var i:= 0 to str.Length-1 do begin
         if(chars[i] >= 'А')and(chars[i] <= 'я')then begin
             result:= true;
             break;
         end 
         else begin
            result:= false;
         end;
     end;
   end;
    /// Читает данные из базы
    public static procedure ReadFile(array_data: List<string>);
     begin
       var sr:= new StreamReader(PATH_TRANSLATE, Encoding.Default);     
       while(not sr.EndOfStream)do begin
           var line:= sr.ReadLine();
           array_data.Add(line);
       end;
      sr.Close();
    end;
    public static procedure SwapLanguages(sender: object; args: EventArgs);
        begin
          if (not isSwapped) then begin
             native_English.Text:= 'Русский';
             native_Russian.Text:= 'Английский';
             Swap(t1,t2);
             isSwapped:= true;
          end else begin
             native_English.Text:= 'Английский';
             native_Russian.Text:= 'Русский';
             Swap(t1,t2);
             isSwapped:= false;
          end; 
        end;
end;    

//----- Используем паттерн Абстрактная фабрика -----//
type TranslaterDirection = abstract class
     internal procedure CheckLanguage();abstract;
     public procedure MainTranslate();abstract;
end;    
/// Отвечает за перевод в направлении Английский - Русский
type TranslaterDirectionEnRu = class (TranslaterDirection)
     ///Проверяет какое поле пустое а какое содержит слово для перевода
     internal procedure CheckLanguage();override;
        begin
           if (TranslaterApiBase.IsEmpty(t1) and (not TranslaterApiBase.IsEmpty(t2)))then begin
               isRu:= true;
               isEn:= false;
           end else if ((not TranslaterApiBase.IsEmpty(t1)) and (TranslaterApiBase.IsEmpty(t2)))then begin
               isEn:= true;
               isRu:= false;
           end;
        end;
     /// Вспомогательная функция, отвечающая за перевод слов
     public static procedure Translate(array_data: List<string>; data: string);
     var isFind: boolean:= false; // Найдено ли слово
     begin
        if (isEn)then begin
           for var i:= 0 to array_data.Count-1 do begin  
              if(array_data[i].startsWith(data))then begin
                  var index_:= array_data[i].IndexOf('-');
                  t2.Text+= array_data[i].Substring(index_ + 1) + Environment.NewLine;
                  isFind:= true;
              end;  
           end;
          
           if(not isFind)then t2.Text:= 'Не найдено'; 
       end
       else if(isRu)then begin
          for var i:= 0 to array_data.Count-1 do begin
             if(array_data[i].endsWith(data))then begin
                  var index_:= array_data[i].IndexOf('-');
                  t1.Text+= array_data[i].Substring(0,index_) + Environment.NewLine;
                  isFind:= true;
             end;
           end;
          
           if(not isFind)then t1.Text:= 'Не найдено';
        end;
     end;
     /// Главная функция, отвечающая за перевод слов
     public procedure MainTranslate();override;
        var array_data:= new List<string>(); // Строки из базы данных, содержащие слова и их перевод
            data: string:= String.Empty; // Слово для поиска
         begin
           CheckLanguage();
           if (String.IsNullOrWhiteSpace(t1.Text) and String.IsNullOrWhiteSpace(t2.Text)) then exit;
           TranslaterApiBase.ReadFile(array_data); // TODO Сделать потом чтение файла только при запуске переводчика
     
            if(isEn)then begin
                TranslaterApiBase.ClearEx(t2);
                data:= t1.Text.Trim();
                if(TranslaterApiBase.isRussian(data))then exit;
                Translate(array_data, data); 
            end
            else if(isRu)then begin
               TranslaterApiBase.ClearEx(t1);
               data:= t2.Text.Trim();
               if (not TranslaterApiBase.isRussian(data))then exit;
               Translate(array_data, data); 
           end;    
        end;
end;
/// Отвечает за перевод в направлении Русский - Английский    
type TranslaterDirectionRuEn = class (TranslaterDirection)
     ///Проверяет какое поле пустое а какое содержит слово для перевода
     internal procedure CheckLanguage();override;
        begin
           if (not(TranslaterApiBase.IsEmpty(t1)) and (TranslaterApiBase.IsEmpty(t2)))then begin
               isRu:= true;
               isEn:= false;
           end else if ((TranslaterApiBase.IsEmpty(t1)) and (not(TranslaterApiBase.IsEmpty(t2))))then begin
               isEn:= true;
               isRu:= false;
           end;
        end;
     /// Вспомогательная функция, отвечающая за перевод слов
     public static procedure Translate(array_data: List<string>; data: string);
     var isFind: boolean:= false; // Найдено ли слово
     begin
        if (isEn)then begin
           for var i:= 0 to array_data.Count-1 do begin  
              if(array_data[i].startsWith(data))then begin
                  var index_:= array_data[i].IndexOf('-');
                  t1.Text+= array_data[i].Substring(index_ + 1) + Environment.NewLine;
                  isFind:= true;
              end; 
           end;
          
           if(not isFind)then t1.Text:= 'Не найдено';
       end 
       else if(isRu)then begin
          for var i:= 0 to array_data.Count-1 do begin
             if(array_data[i].endsWith(data))then begin
                  var index_:= array_data[i].IndexOf('-');
                  t2.Text+= array_data[i].Substring(0,index_) + Environment.NewLine;
                  isFind:= true;
             end; 
           end;
          
           if(not isFind)then t2.Text:= 'Не найдено';
        end;
     end;
     /// Главная функция, отвечающая за перевод слов
     public procedure MainTranslate();override;
        var array_data:= new List<string>(); // Строки из базы данных, содержащие слова и их перевод
            data: string:= String.Empty; // Слово для поиска
         begin
           CheckLanguage();
           if (String.IsNullOrWhiteSpace(t1.Text) and String.IsNullOrWhiteSpace(t2.Text)) then exit;
           TranslaterApiBase.ReadFile(array_data); // TODO Сделать потом чтение файла только при запуске переводчика
     
            if(isEn)then begin
                TranslaterApiBase.ClearEx(t1);
                data:= t2.Text.Trim();
          
                if(TranslaterApiBase.isRussian(data))then exit;
                Translate(array_data, data);
            end
            else if(isRu)then begin
               TranslaterApiBase.ClearEx(t2);
               data:= t1.Text.Trim();
               if (not TranslaterApiBase.isRussian(data))then exit;
               Translate(array_data, data);
           end;    
        end;
end;    
/// Вызывает нужную реализацию MainTranslate() в зависимости от направления перевода
type MainTranslater = class
    private static t: TranslaterDirection;
    /// Главная функция, отвечающая за перевод слов при нажатии клавиши Shift
    public static procedure MainTranslateWithShift(sender: object; args: KeyEventArgs);
       begin
          if (args.KeyData = Keys.ShiftKey) then begin
             if (not isSwapped)then begin
                 t:= new TranslaterDirectionEnRu();
                 t.MainTranslate();
             end else begin
                 t:= new TranslaterDirectionRuEn();
                 t.MainTranslate();
            end;
          end;
       end;
    
    public static procedure MainTranslate(sender: object; args: EventArgs);   
       begin
          if (not isSwapped)then begin
             t:= new TranslaterDirectionEnRu();
             t.MainTranslate();
          end else begin
             t:= new TranslaterDirectionRuEn();
             t.MainTranslate();
          end;
       end;
end;

/// Класс, отвечающий за оформление и внешний вид переводчика
type TranslaterForm = class
     private native_header:= new PictureBox();
             native_Collapse:= new &Label();
             native_Close:= new &Label();
             native_title:= new &Label();
             panel1:= new Panel();
             native_menu:= new MenuStrip();
             native_find:= new ToolStripMenuItem();
                         
     public constructor();
       begin
          Init();
       end;

     internal procedure Init();
        begin
          f.BackColor := Color.FromArgb(35,35,35);
          f.ClientSize := new Size(886, 330);      
          f.FormBorderStyle := FormBorderStyle.None;
          f.KeyUp += MainTranslater.MainTranslateWithShift;
          f.KeyPreview:= true;

          native_header.BackColor := Color.FromArgb(35,35,35);
          native_header.BorderStyle := BorderStyle.FixedSingle;
          native_header.Dock := DockStyle.Top;
          native_header.Location := new Point(0, 0);
          native_header.Size := new Size(886, 42);
          native_header.MouseDown += Mouse_Down;
          native_header.MouseMove += Mouse_Move;
          native_header.MouseUp += Mouse_Up;

          native_Collapse.BackColor:= Color.Transparent;
          native_Collapse.Anchor := (AnchorStyles((AnchorStyles.Top or AnchorStyles.Right)));
          native_Collapse.Font := new Font('Arial', 15.75, FontStyle.Italic, GraphicsUnit.Point, (Byte(204)));
          native_Collapse.ForeColor := Color.White;
          native_Collapse.Location := new Point(814, 4);
          native_Collapse.Size := new Size(35, 35);
          native_Collapse.Text := '-';
          native_Collapse.TextAlign := ContentAlignment.MiddleCenter;
          native_Collapse.Click += CollapseApplication;
          native_Collapse.MouseHover += (o,e) -> begin native_Collapse.BackColor := Color.FromArgb(22,22,22); end;
          native_Collapse.MouseLeave += (o,e) -> begin native_Collapse.BackColor := Color.Transparent; end;

          native_Close.BackColor:= Color.Transparent;
          native_Close.Anchor := (AnchorStyles((AnchorStyles.Top or AnchorStyles.Right)));
          native_Close.Font := new Font('Arial', 16, FontStyle.Italic, GraphicsUnit.Point, (Byte(0)));
          native_Close.ForeColor := Color.White;
          native_Close.Location := new Point(850, 4);
          native_Close.Size := new Size(35, 35);
          native_Close.Text := 'x';
          native_Close.TextAlign := ContentAlignment.MiddleCenter;
          native_Close.Click += CloseApplication;
          native_Close.MouseHover += (o,e) -> begin native_Close.BackColor := Color.FromArgb(255, 83, 83); end;
          native_Close.MouseLeave += (o,e) -> begin native_Close.BackColor := Color.Transparent; end;

          native_title.BackColor:= Color.Transparent;
          native_title.Anchor := (AnchorStyles((AnchorStyles.Top or AnchorStyles.Right)));
          native_title.Font := new Font('Consolas', 13, FontStyle.Regular, GraphicsUnit.Point, (Byte(204)));
          native_title.ForeColor := Color.White;
          native_title.Location := new Point(26, 9);
          native_title.Size := new Size(312, 21);
          native_title.Text := 'Translater v3.2.1.1 2020';
          native_title.MouseDown += Mouse_Down;
          native_title.MouseMove += Mouse_Move;
          native_title.MouseUp += Mouse_Up;
          // panel1
          panel1.BackColor := Color.FromArgb(35,35,35);
          panel1.Controls.Add(native_translate);
          panel1.Controls.Add(native_Swap);
          panel1.Controls.Add(t2);
          panel1.Controls.Add(t1);
          panel1.Controls.Add(native_Russian);
          panel1.Controls.Add(native_English);
          panel1.Controls.Add(native_Clear);
          panel1.Controls.Add(native_copy);
          panel1.Controls.Add(native_paste);
          panel1.Dock := DockStyle.Fill;
          panel1.Location := new Point(0, 42);
          panel1.BorderStyle := BorderStyle.FixedSingle;
          panel1.Size := new Size(886, 356);
          
          // native_Clear
          native_Clear.BackColor := Color.FromArgb(35,35,35);
          native_Clear.Font := new Font('Courier New', 12, FontStyle.Italic, GraphicsUnit.Point, (Byte(204)));
          native_Clear.ForeColor := Color.LightSeaGreen;
          native_Clear.Location := new Point(12, 10);
          native_Clear.Size := new Size(38, 29);
          native_Clear.Text := 'X';
          native_Clear.Click += TranslaterApiBase.Clear;
          
          // Кнопка Перевести
          native_translate.BackColor := Color.FromArgb(35,35,35);
          native_translate.Font := new System.Drawing.Font('Courier New', 12, FontStyle.Italic, System.Drawing.GraphicsUnit.Point, (System.Byte(204)));
          native_translate.ForeColor := System.Drawing.Color.LightSeaGreen;
          native_translate.Location := new System.Drawing.Point(54, 10);
          native_translate.Size := new System.Drawing.Size(38, 29);
          native_translate.Text := 'T';
          native_translate.Click += MainTranslater.MainTranslate;
          
          native_copy.BackColor := Color.FromArgb(35,35,35);
          native_copy.Font := new System.Drawing.Font('Courier New', 12, FontStyle.Italic, System.Drawing.GraphicsUnit.Point, (System.Byte(204)));
          native_copy.ForeColor := System.Drawing.Color.LightSeaGreen;
          native_copy.Location := new System.Drawing.Point(96, 10);
          native_copy.Size := new System.Drawing.Size(38, 29);
          native_copy.Text := 'C';
          native_copy.Click += (o,e) -> begin t1.SelectAll(); t1.Copy(); end;
          
          native_paste.BackColor := Color.FromArgb(35,35,35);
          native_paste.Font := new System.Drawing.Font('Courier New', 12, FontStyle.Italic, System.Drawing.GraphicsUnit.Point, (System.Byte(204)));
          native_paste.ForeColor := System.Drawing.Color.LightSeaGreen;
          native_paste.Location := new System.Drawing.Point(138, 10);
          native_paste.Size := new System.Drawing.Size(38, 29);
          native_paste.Text := 'P';
          native_paste.Click += (o,e) -> begin t1.SelectAll(); t1.Paste(); end;
          
          native_English.BackColor:= Color.Transparent;
          native_English.Anchor := (AnchorStyles((AnchorStyles.Top or AnchorStyles.Right)));
          native_English.Font := new Font('Consolas', 13, FontStyle.Italic, GraphicsUnit.Point, (Byte(204)));
          native_English.ForeColor := Color.White;
          native_English.Location := new Point(200, 10);
          native_English.Size := new Size(133, 50);
          native_English.Text := 'Английский';
          
          native_Russian.BackColor:= Color.Transparent;
          native_Russian.Anchor := (AnchorStyles((AnchorStyles.Top or AnchorStyles.Right)));
          native_Russian.Font := new Font('Consolas', 13, FontStyle.Italic, GraphicsUnit.Point, (Byte(204)));
          native_Russian.ForeColor := Color.White;
          native_Russian.Location := new Point(603, 10);
          native_Russian.Size := new Size(133, 30);
          native_Russian.Text := 'Русский';

          t1.BorderStyle := BorderStyle.FixedSingle;
          t1.Font := new Font('Consolas', 13, FontStyle.Regular, GraphicsUnit.Point, (Byte(0)));
          t1.ForeColor := Color.White;
          t1.Location := new Point(12, 42);
          t1.Multiline := true;
          t1.ScrollBars := ScrollBars.Vertical;
          t1.Size := new Size(440, 235);
          t1.BackColor := Color.FromArgb(35,35,35);

          t2.BackColor := Color.FromArgb(35,35,35);
          t2.BorderStyle := BorderStyle.FixedSingle;
          t2.Font := new Font('Consolas', 13, FontStyle.Regular, GraphicsUnit.Point, (Byte(0)));
          t2.ForeColor := Color.White;
          t2.Location := new Point(458, 42);
          t2.Multiline := true;
          t2.ScrollBars := ScrollBars.Vertical;
          t2.Size := new Size(416, 235);
          // Кнопка Поменять языки местами
          native_Swap.BackColor := Color.FromArgb(35,35,35);
          native_Swap.Font := new Font('Courier New', 11, FontStyle.Italic, GraphicsUnit.Point, (Byte(204)));
          native_Swap.ForeColor := Color.LightSeaGreen;
          native_Swap.Location := new Point(425, 10);
          native_Swap.Size := new Size(50, 27);
          native_Swap.Text := '<->';
          native_Swap.Click += TranslaterApiBase.SwapLanguages;
       
          f.Controls.AddRange(new Control[5] (panel1, native_title, native_Close, native_Collapse, native_header));
        end;
     
     public procedure CloseApplication(sender: object; args: EventArgs);
        begin
          ButtonsWindowEx(native_Close);
        end;
        
     public procedure CollapseApplication(sender: object; args: EventArgs);
        begin
          ButtonsWindowEx(native_Collapse);
        end;   
     /// Главная функция для меток Закрыть и Свернуть
     private procedure ButtonsWindowEx(lab: &Label);
         begin
           if (lab.Text = '-')then begin
               if (f.WindowState = FormWindowState.Normal)then
                    f.WindowState:= FormWindowState.Minimized;
           end else if (lab.Text = 'x')then begin
               Application.Exit();
           end;
         end;

     private OffsetX, OffsetY: integer;
            isMouseDown: boolean:= false;
   
     public procedure Mouse_Down(sender: object; e: MouseEventArgs);
       begin   
         if (e.Button = System.Windows.Forms.MouseButtons.Left)then begin
             var screen : Point := f.PointToScreen(new Point(e.X, e.Y));
             OffsetX:= f.Location.X - screen.X;
             OffsetY:= f.Location.Y - screen.Y;
             isMouseDown:= true;
         end;
       end;
       
     public procedure Mouse_Move(sender: object; e: MouseEventArgs);
       begin
         if (isMouseDown)then begin
           var mousePos:= Control.MousePosition;
           mousePos.Offset(OffsetX, OffsetY);
           f.Location:= mousePos;
         end;
       end;
       
     public procedure Mouse_Up(sender: object; e: MouseEventArgs);
       begin
         isMouseDown:= false;
       end;
end;

begin
if (&File.Exists(PATH_TRANSLATE))then begin
    var translater_:= new TranslaterForm();
    Application.Run(f);
end else begin
   MessageBox.Show('Не удалось найти файл-базу переводчика', 'Error', 
      MessageBoxButtons.OK,
      MessageBoxIcon.Error,
      MessageBoxDefaultButton.Button1);
 end; 
end.
