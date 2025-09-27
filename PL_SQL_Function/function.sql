-- user table
CREATE TABLE MY_USERS (
    USER_ID        NUMBER,
    USER_NAME      VARCHAR2(10),
    USER_PASSWORD  VARCHAR2(20),
    USER_ACTIVATED NUMBER DEFAULT 0,
    PRIMARY KEY (USER_ID)
);



-- function
FUNCTION my_auth (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN AS
    found NUMBER := 0;
BEGIN
    SELECT 1 INTO found 
    FROM MY_USERS
    WHERE LOWER(user_name) = LOWER(p_username)
      AND LOWER(user_password) = LOWER(p_password)
      AND user_activated = 1;

    RETURN TRUE;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
END;

