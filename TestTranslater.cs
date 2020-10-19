using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
namespace TestTranslater
{
	public static class IOOp {
		public static string ReadAllText(string filepath) {
			string line = null;
			using (StreamReader sr = new StreamReader(filepath, Encoding.Default)) {
				line = sr.ReadToEnd();
			}
			return line;
		}
		
		public static string ReadLine(string filepath) {
			string line = null;
			using (StreamReader sr = new StreamReader(filepath, Encoding.Default)) {
				line = sr.ReadLine();
			}
			return line;
		}
		
		public static void WriteLine(string filepath, string text) {
			using (StreamWriter sw = new StreamWriter(filepath, true, Encoding.Default)) {
			    sw.WriteLine(text);
			}
		}
		// Существует ли слово в базе
		public static bool IsExistsWordInBase(List<string> lines, string word) {
			foreach(var line in lines) {
				if (line.StartsWith(word, StringComparison.Ordinal) && line == word) {
					return true;
				}
			}
			return false;
		}
		// Возвращает массив: 1-й элемент - английское слово , 2-й элемент - русский перевод
		public static string[] GetEnglishAndRussian(string line) {
			string[] en_ru_arrs = new string[2];
			int indexSeparator = line.IndexOf(" - ", StringComparison.Ordinal);
			en_ru_arrs[0] = line.Substring(0, indexSeparator).Trim();
			en_ru_arrs[1] = line.Substring(indexSeparator + 1).Trim();
			return en_ru_arrs;
		}
		
		public static string Translate(List<string> array_data, string data) {
			bool isFind = false;
			StringBuilder builder = new StringBuilder();
			
			for (int i = 0; i < array_data.Count; ++i) {
				if (array_data[i].StartsWith(data.Trim())) {
					var index = array_data[i].IndexOf('-');
					builder.AppendLine(array_data[i].Substring(index + 1));
					isFind = true;
				}
			}
			if (!isFind) return "Не найдено";
			return builder.ToString();
		}
	}
	
	
	public class Tester {
		// Путь к базе нашего переводчика
		public string BasePath = @"C:\Users\fdshfgas\Documents\_USB_\Разработки 2020\App 2020\TRANSLATER\translate.txt";
		// Путь к файлу куда будет писать слова котоых нет в нашей базе данных
		// формат слов : english - русский
		public string NotePath = @"C:\Users\fdshfgas\Desktop\EmptyWords.txt";
		// Дополнительная база которую нужно сканировать
		public string ENRUSPath = @"C:\Users\fdshfgas\Desktop\ENRUS.txt";
		// список строк базы
		public List<string> ListLines = new List<string>();
		
		public string[] Lines;
		
		public void Testize() {
			Console.WriteLine("Please wait...");
			List<string> baseLines = IOOp.ReadAllText(BasePath).Split('\n').ToList();
			string text = IOOp.ReadAllText(ENRUSPath);
			Lines = text.Split('\n');
			string[] en_ru = new string[2];
			
			for (int i = 0; i < Lines.Count() - 1; i += 2) {
				string translation = IOOp.Translate(baseLines, Lines[i]);
				
				if (translation.Contains("\n")) {
					bool isExists = false;
					string[] parts = translation.Split('\n');
					
					foreach (string part in parts) {
						if (part.Trim() == Lines[i+1].Trim()) {
							isExists = true;
							break;
						}
						else isExists = false;
					}
					if (!isExists) {
						isExists = false;
						IOOp.WriteLine(NotePath, Lines[i].Trim() + " - " + Lines[i+1].Trim());
					}
				}
				
				if (translation.Trim() == "Не найдено") {
					IOOp.WriteLine(NotePath, Lines[i].Trim() + " - " + Lines[i+1].Trim());
				}
				translation = null;
			}
			Console.WriteLine("End work");
		}
		
	}
	
	
	class Program
	{
		public static void Main(string[] args)
		{
			// TEST 1: Проверка перевода с английского на русский
//			Tester tester = new Tester();
//			List<string> lines = IOOp.ReadAllText(tester.BasePath).Split('\n').ToList();
			
//			Console.WriteLine(IOOp.Translate(lines, "human"));
			
			Tester tester = new Tester();
			tester.Testize();
			Console.ReadKey(true);
		}
	}
}
