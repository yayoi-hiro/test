using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

namespace ParseLogViewer
{
    class Parser
    {
        const string datetimePrefix = "yyyy/MM/dd HH:mm:ss.fff ";
        const string eventPrefix = "Event: ";
        const string resultPrefix = "RESULT: ";
        const string currentStatePrefix = "Current State: ";
        const string stateTransitionPrefix = "State Transition: ";
        const string nextCommandPrefix = "Next Command: ";
        const string startKeyword = "[Start]";

        private static readonly ParseRule[] Rules =
        {
            new ParseRule(eventPrefix),
            new ParseRule(resultPrefix),
            new ParseRule(currentStatePrefix),
            new ParseRule(nextCommandPrefix),
            new ParseRule(stateTransitionPrefix, s => s.Split('→')[1].Trim())
        };

        public void Parse()
        {
            string filePath = @".\logtest.txt";

            Dictionary<string, string> prevInfo = new Dictionary<string, string>();
            Dictionary<string, string> currentInfo = new Dictionary<string, string>();
            int num = 1;

            foreach (string line in File.ReadLines(filePath))
            {
                if(line.Length <= datetimePrefix.Length)
                {
                    continue;
                }

                string msgtext = line.Substring(datetimePrefix.Length);
                //Debug.WriteLine(msgtext);

                if (msgtext.StartsWith(startKeyword))
                {
                    Debug.WriteLine("********************");
                    Debug.WriteLine("");
                    num = 1;
                    continue;
                }

                foreach (var rule in Rules)
                {
                    if (msgtext.StartsWith(rule.Prefix))
                    {
                        string value = msgtext.Substring(rule.Prefix.Length);
                        currentInfo[rule.Prefix] = rule.Parser(value);

                        if(rule.Prefix == stateTransitionPrefix)
                        {
                            // State Transition が来たら1レコード終了
                            Debug.WriteLine(Serialized(prevInfo, currentInfo, num));
                            Debug.WriteLine("");

                            prevInfo = currentInfo;
                            currentInfo = new Dictionary<string, string>();
                            num++;
                        }
                        break;
                    }
                }


            }
        }

        public string Serialized(Dictionary<string, string> prev, Dictionary<string, string> current, int num)
        {

            string GetValue(Dictionary<string, string> info, string key)
            {
                return info.TryGetValue(key, out var value) ? value : "";
            }

            string eventName = GetValue(current, eventPrefix);
            string resultName = GetValue(current, resultPrefix);
            string commandName = GetValue(prev, nextCommandPrefix);
            string nextCommandName = GetValue(current, nextCommandPrefix);
            string stateName = GetValue(current, currentStatePrefix);
            string nextStateName = GetValue(current, stateTransitionPrefix);
            return $"{num:D3}.Flow : {commandName}→({eventName} / {resultName})→{nextCommandName}\r\n" +
                $"{num:D3}.State: {stateName}→( {eventName} / {resultName})→{nextStateName}";
        }
    }
}
