using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParseLogViewer
{
    class ParseRule
    {
        public string Prefix { get; }
        public Func<string, string> Parser { get; }

        public ParseRule(string prefix, Func<string, string> parser = null)
        {
            Prefix = prefix;
            Parser = parser ?? (s => s);
        }
    } 
}
