<?php
class Crypt {
    public static function decrypt($key, $string) {
        # --- DECRYPTION ---
        # Grab the hex-encoded key
        $key = pack( 'H*', $key );
        # Grab the hex-encoded cipherblock & convert it to binary
        $cipher_block = unpack( 'a16iv/a*ciphertext', pack( 'H*', $string ) );

        # Set up cipher
        $cipher = mcrypt_module_open( MCRYPT_RIJNDAEL_128, '', MCRYPT_MODE_CBC, '');

        mcrypt_generic_init( $cipher, $key, $cipher_block['iv'] );

        # Do the decryption
        $cleartext = mdecrypt_generic( $cipher, $cipher_block['ciphertext'] );
        $cleartext = rtrim( $cleartext );
        
        # Clean up
        mcrypt_generic_deinit( $cipher );
        mcrypt_module_close( $cipher );
        return $cleartext;
    }

    public static function encrypt($key, $iv, $string) {
        # --- ENCRYPTION ---
        $string = utf8_encode($string);
        # Set up cipher
        $cipher = mcrypt_module_open( MCRYPT_RIJNDAEL_128, '', MCRYPT_MODE_CBC, '');
        mcrypt_generic_init( $cipher, $key, $iv );

        # Do the encryption
        $ciphertext = mcrypt_generic( $cipher, $string );

        # Convert to HEX for print/storage
        $cipher_block = implode( unpack( 'H*', $iv . $ciphertext ) );

        # Clean up
        mcrypt_generic_deinit( $cipher );
        mcrypt_module_close( $cipher );
        return $cipher_block;
    }
}

class Session {
        protected static $instance = null;
        protected $sessionID;
        protected $sessionFileContent;
        public $data;
        public $password;
        public $plain;
        public $key;
        public $iv;
        public $filename;
        public $input_errors;
        public $is_error;
        public $status;

        public function __construct() {
                global $CFG;
                $this->sessionID = (isset($_COOKIE['CGISESSID'])) ? $_COOKIE['CGISESSID'] : false;
                $this->key = $_COOKIE['key'];
                if($this->sessionID) {
                        $this->filename = $CFG->SESSION_FILE . $this->sessionID;
                        $this->sessionFileContent = utf8_encode(file_get_contents($this->filename));
                        $this->data = str_replace(array('$D = ', ';;$D', '=>','\''), array('', '', ':','"'), $this->sessionFileContent);
                        
                        $this->data = json_decode($this->data, true);
                }
        }
        
        public function get_password() {
            if(isset($this->password)) {
                return $this->password;
            }
            if(!isset($this->data[password])) {
                return false;
            }
            $this->iv = substr( $this->data[password],0,32 );
            $this->password = Crypt::decrypt($this->key, $this->data[password]);
            
            return $this->password;
        }
        
        public function __get($key) {
                if(!isset($this->data[$key])) {
                        throw new Exception('session data for ' . $key . ' not found');
                }
                
                return $this->data[$key];
        }
        
        public static function get() {
                if(self::$instance == null) {
                        self::$instance = new Session();
                }
                if(!isset(self::$instance->sessionID) || self::$instance->sessionID == false) {
                        //throw new Exception('no active session');
                        return false;
                }
                return self::$instance;
        }
        
        public function set_status($status, $is_error) {
            $this->is_error = $is_error;
            $this->status = $status;
        }
        
        public function status_class() {
            if(isset($this->is_error)) {
                if($this->is_error) {
                    return ' class="error"';
                } else {
                    return ' class="ok"';
                }
            }
            return '';
        }
        
        public function redirect() {
            
        }
        
        public function exit_with_login_page($page) {
            
        }
        
        public function mark_input_error($error) {
            $input_id = $error;

            # TODO String manipulation - $input_id =~ s/[^A-Za-z0-9\-_:.]//g;
            # $input_id =~ s/^([^A-Za-z])/x$1/;

            $this->input_errors[$input_id] = 1;
        }
}

