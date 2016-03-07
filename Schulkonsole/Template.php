<?php
class Template {
	protected $leftDelimiter = '<!--#';
	protected $rightDelimiter = '-->';
	
	protected $raw;
	protected $parsed;
	
	public function __construct($filename) {
		if(!file_exists($filename)) {
			throw new Exception('Templatedatei ' . basename($filename) . ' nicht gefunden');
		}
		
		$this->raw = file($filename);
	}
	
	public function __toString() {
		foreach($this->raw as $line) {
			echo $this->compile($line);
		}
	}
	
	public function compile($string) {
		$matches = array();
		preg_match_all('/' . $this->leftDelimiter . '(.*)' . $this->rightDelimiter . '/sU', $string, $matches);
		
		$templateTags = $matches[1];
		foreach($templateTags as $args) {
			$args = explode(' ', trim($args));
			$tag = array_shift($args);
			
			$this->compileTag($tag, $args);
		}
	}
	
	public function compileTag($tag, $args) {
		$args = $this->compileArguments($args);
		
		switch($tag) {
			case 'if':
				$this->checkArgumentList($args, array('expr'));
				
				break;
			case 'echo':
				$this->checkArgumentList($args, array('var'));
				
				break;
			case 'set':
				$this->checkArgumentList($args, array('var', 'value'));
				
				break;
			case 'include':
				$this->checkArgumentList($args, array('file'));
				
				break;
		}
		
		d($tag);
		d($args);
		d("\n\n");
	}
	
	public function compileArguments($args) {
		$compiledArgs = array();
		
		foreach($args as $arg) {
			$arg = explode('=', $arg);
			
			$compiledArgs[$arg[0]] = str_replace('"', '', $arg[1]);
		}
		
		return $compiledArgs;
	}
	
	private function checkArgumentList($argList, $neededArgs) {
		foreach($neededArgs as $arg) {
			if(!isset($argList[$arg])) {
				throw new TemplateException('Fehlendes Argument ' . $arg);
			}
		}
	}
}

class TemplateException extends Exception {
	public function __construct($message) {
		parent::__construct($message);
	}
}